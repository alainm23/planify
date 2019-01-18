/*-*- Mode: C; tab-width: 8; indent-tabs-mode: t; c-basic-offset: 8 -*- */
/* e-book-sqlite.c
 *
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
 * SECTION: e-book-sqlite
 * @include: libedata-book/libedata-book.h
 * @short_description: An SQLite storage facility for addressbooks
 *
 * The #EBookSqlite is an API for storing and looking up #EContact(s)
 * in an SQLite database. It also supports a lean index mode via
 * the #EbSqlVCardCallback, if you are in a situation where it is
 * not convenient to store the vCards directly in the SQLite. It is
 * however recommended to avoid storing contacts in separate storage
 * if at all possible, as this will decrease performance of searches
 * an also contribute to flash wear.
 *
 * The API is thread safe, with special considerations to be made
 * around e_book_sqlite_lock() and e_book_sqlite_unlock() for
 * the sake of isolating transactions across threads.
 *
 * Any operations which can take a lot of time to complete (depending
 * on the size of your addressbook) can be cancelled using a #GCancellable.
 *
 * Depending on your summary configuration, your mileage will vary. Refer
 * to the #ESourceBackendSummarySetup for configuring your addressbook
 * for the type of usage you mean to make of it.
 */

#include "e-book-sqlite.h"

#include <locale.h>
#include <string.h>
#include <errno.h>

#include <glib/gi18n.h>
#include <glib/gstdio.h>

#include <sqlite3.h>

/* For e_sqlite3_vfs_init() */
#include <libebackend/libebackend.h>

#include "e-book-backend-sexp.h"

#define E_BOOK_SQLITE_GET_PRIVATE(obj) \
	(G_TYPE_INSTANCE_GET_PRIVATE \
	((obj), E_TYPE_BOOK_SQLITE, EBookSqlitePrivate))

/******************************************************
 *                 Debugging Macros                   *
 ******************************************************
 * Run EDS with EBSQL_DEBUG=statements:explain to print 
 * all statements and explain query plans.
 *
 * Use any of the values below to select which debug
 * to enable.
 */
#define EBSQL_ENV_DEBUG   "EBSQL_DEBUG"

typedef enum {
	EBSQL_DEBUG_STATEMENTS    = 1 << 0,  /* Output all executed statements */
	EBSQL_DEBUG_EXPLAIN       = 1 << 1,  /* Output SQLite's query plan for SELECT statements */
	EBSQL_DEBUG_LOCKS         = 1 << 2,  /* Print which function locks and unlocks the mutex */
	EBSQL_DEBUG_ERRORS        = 1 << 3,  /* Print all errors which are set */
	EBSQL_DEBUG_SCHEMA        = 1 << 4,  /* Debugging the schema building / upgrading */
	EBSQL_DEBUG_INSERT        = 1 << 5,  /* Debugging contact insertions */
	EBSQL_DEBUG_FETCH_VCARD   = 1 << 6,  /* Print invocations of the EbSqlVCardCallback fallback */
	EBSQL_DEBUG_CURSOR        = 1 << 7,  /* Print information about EbSqlCursor operations */
	EBSQL_DEBUG_CONVERT_E164  = 1 << 8,  /* Print information e164 phone number conversions in vcards */
	EBSQL_DEBUG_REF_COUNTS    = 1 << 9,  /* Print about shared EBookSqlite instances, print when finalized */
	EBSQL_DEBUG_CANCEL        = 1 << 10, /* Print information about GCancellable cancellations */
	EBSQL_DEBUG_PREFLIGHT     = 1 << 11, /* Print information about query preflighting */
	EBSQL_DEBUG_TIMING        = 1 << 12, /* Print information about timing */
} EbSqlDebugFlag;

static const GDebugKey ebsql_debug_keys[] = {
	{ "statements",     EBSQL_DEBUG_STATEMENTS   },
	{ "explain",        EBSQL_DEBUG_EXPLAIN      },
	{ "locks",          EBSQL_DEBUG_LOCKS        },
	{ "errors",         EBSQL_DEBUG_ERRORS       },
	{ "schema",         EBSQL_DEBUG_SCHEMA       },
	{ "insert",         EBSQL_DEBUG_INSERT       },
	{ "fetch-vcard",    EBSQL_DEBUG_FETCH_VCARD  },
	{ "cursor",         EBSQL_DEBUG_CURSOR       },
	{ "e164",           EBSQL_DEBUG_CONVERT_E164 },
	{ "ref-counts",     EBSQL_DEBUG_REF_COUNTS   },
	{ "cancel",         EBSQL_DEBUG_CANCEL       },
	{ "preflight",      EBSQL_DEBUG_PREFLIGHT    },
	{ "timing",         EBSQL_DEBUG_TIMING       },
};

static EbSqlDebugFlag ebsql_debug_flags = 0;

static void
ebsql_init_debug (void)
{
	static gboolean initialized = FALSE;

	if (G_UNLIKELY (!initialized)) {
		const gchar *env_string;

		env_string = g_getenv (EBSQL_ENV_DEBUG);

		if (env_string != NULL)
			ebsql_debug_flags =
				g_parse_debug_string (
					env_string,
					ebsql_debug_keys,
					G_N_ELEMENTS (ebsql_debug_keys));
	}
}

static const gchar *
ebsql_error_str (EBookSqliteError code)
{
	switch (code) {
		case E_BOOK_SQLITE_ERROR_ENGINE:
			return "engine";
		case E_BOOK_SQLITE_ERROR_CONSTRAINT:
			return "constraint";
		case E_BOOK_SQLITE_ERROR_CONTACT_NOT_FOUND:
			return "contact not found";
		case E_BOOK_SQLITE_ERROR_INVALID_QUERY:
			return "invalid query";
		case E_BOOK_SQLITE_ERROR_UNSUPPORTED_QUERY:
			return "unsupported query";
		case E_BOOK_SQLITE_ERROR_UNSUPPORTED_FIELD:
			return "unsupported field";
		case E_BOOK_SQLITE_ERROR_END_OF_LIST:
			return "end of list";
		case E_BOOK_SQLITE_ERROR_LOAD:
			return "load";
	}

	return "(unknown)";
}

static const gchar *
ebsql_origin_str (EbSqlCursorOrigin origin)
{
	switch (origin) {
		case EBSQL_CURSOR_ORIGIN_CURRENT:
			return "current";
		case EBSQL_CURSOR_ORIGIN_BEGIN:
			return "begin";
		case EBSQL_CURSOR_ORIGIN_END:
			return "end";
	}

	return "(invalid)";
}

#define EBSQL_NOTE(type,action) \
	G_STMT_START { \
		if (ebsql_debug_flags & EBSQL_DEBUG_##type) \
			{ action; }; \
	} G_STMT_END

#define EBSQL_LOCK_MUTEX(mutex) \
	G_STMT_START { \
		if (ebsql_debug_flags & EBSQL_DEBUG_LOCKS) { \
			g_printerr ("%s: Locking %s\n", G_STRFUNC, #mutex); \
			g_mutex_lock (mutex); \
			g_printerr ("%s: Locked %s\n", G_STRFUNC, #mutex); \
		} else { \
			g_mutex_lock (mutex); \
		} \
	} G_STMT_END

#define EBSQL_UNLOCK_MUTEX(mutex) \
	G_STMT_START { \
		if (ebsql_debug_flags & EBSQL_DEBUG_LOCKS) { \
			g_printerr ("%s: Unlocking %s\n", G_STRFUNC, #mutex); \
			g_mutex_unlock (mutex); \
			g_printerr ("%s: Unlocked %s\n", G_STRFUNC, #mutex); \
		} else { \
			g_mutex_unlock (mutex); \
		} \
	} G_STMT_END

/* Format strings are passed through dgettext(), need to be reformatted */
#define EBSQL_SET_ERROR(error, code, fmt, args...) \
	G_STMT_START { \
		if (ebsql_debug_flags & EBSQL_DEBUG_ERRORS) { \
			gchar *format = g_strdup_printf ( \
				"ERR [%%s]: Set error code '%%s': %s\n", fmt); \
			g_printerr (format, G_STRFUNC, \
				    ebsql_error_str (code), ## args); \
			g_free (format); \
		} \
		g_set_error (error, E_BOOK_SQLITE_ERROR, code, fmt, ## args); \
	} G_STMT_END

#define EBSQL_SET_ERROR_LITERAL(error, code, detail) \
	G_STMT_START { \
		if (ebsql_debug_flags & EBSQL_DEBUG_ERRORS) { \
			g_printerr ("ERR [%s]: " \
				    "Set error code %s: %s\n", \
				    G_STRFUNC, \
				    ebsql_error_str (code), detail); \
		} \
		g_set_error_literal (error, E_BOOK_SQLITE_ERROR, code, detail); \
	} G_STMT_END

/* EBSQL_LOCK_OR_RETURN:
 * @ebsql: The #EBookSqlite
 * @cancellable: A #GCancellable passed into an API
 * @val: Value to return if this check fails
 *
 * This will first lock the mutex and then check if
 * the passed cancellable is valid or invalid, it can
 * be invalid if it differs from a cancellable passed
 * to a toplevel transaction via e_book_sqlite_lock().
 *
 * If the check fails, the lock is released and then
 * @val is returned.
 */
#define EBSQL_LOCK_OR_RETURN(ebsql, cancellable, val) \
	G_STMT_START { \
		EBSQL_LOCK_MUTEX (&(ebsql)->priv->lock); \
		if (cancellable != NULL && (ebsql)->priv->cancel &&	    \
		    (ebsql)->priv->cancel != cancellable) { \
			g_warning ("The GCancellable passed to `%s' " \
				   "is not the same as the cancel object " \
				   "passed to e_book_sqlite_lock()", \
				   G_STRFUNC); \
			EBSQL_UNLOCK_MUTEX (&(ebsql)->priv->lock); \
			return val; \
		} \
	} G_STMT_END

/* Set an error code from an sqlite_exec() or sqlite_step() return value & error message */
#define EBSQL_SET_ERROR_FROM_SQLITE(error, code, message) \
	G_STMT_START { \
		if (code == SQLITE_CONSTRAINT) { \
			EBSQL_SET_ERROR_LITERAL (error, \
						 E_BOOK_SQLITE_ERROR_CONSTRAINT, \
						 errmsg); \
		} else if (code == SQLITE_ABORT) { \
			if (ebsql_debug_flags & EBSQL_DEBUG_ERRORS) { \
				g_printerr ("ERR [%s]: Set cancelled error\n", \
					    G_STRFUNC); \
			} \
			g_set_error (error, \
				     G_IO_ERROR, \
				     G_IO_ERROR_CANCELLED, \
				     "Operation cancelled: %s", errmsg); \
		} else { \
			EBSQL_SET_ERROR (error, \
					 E_BOOK_SQLITE_ERROR_ENGINE, \
					 "SQLite error code `%d': %s", \
					 code, errmsg); \
		} \
	} G_STMT_END

#define FOLDER_VERSION                12
#define INSERT_MULTI_STMT_BYTES       128
#define COLUMN_DEFINITION_BYTES       32
#define GENERATED_QUERY_BYTES         1024

#define DEFAULT_FOLDER_ID            "folder_id"

/* We use a 64 bitmask to track which auxiliary tables
 * are needed to satisfy a query, it's doubtful that
 * anyone will need an addressbook with 64 fields configured
 * in the summary.
 */
#define EBSQL_MAX_SUMMARY_FIELDS      64

/* The number of SQLite virtual machine instructions that are
 * evaluated at a time, the user passed GCancellable is
 * checked between each batch of evaluated instructions.
 */
#define EBSQL_CANCEL_BATCH_SIZE       200

/* Number of contacts to relocalize at a time
 * while relocalizing the whole database
 */
#define EBSQL_UPGRADE_BATCH_SIZE      20

#define EBSQL_ESCAPE_SEQUENCE        "ESCAPE '^'"

/* Names for custom functions */
#define EBSQL_FUNC_COMPARE_VCARD     "compare_vcard"
#define EBSQL_FUNC_FETCH_VCARD       "fetch_vcard"
#define EBSQL_FUNC_EQPHONE_EXACT     "eqphone_exact"
#define EBSQL_FUNC_EQPHONE_NATIONAL  "eqphone_national"
#define EBSQL_FUNC_EQPHONE_SHORT     "eqphone_short"

/* Fallback collations are generated as with a prefix and an EContactField name */
#define EBSQL_COLLATE_PREFIX         "ebsql_"

/* A special vcard attribute that we use only for private vcards */
#define EBSQL_VCARD_SORT_KEY         "X-EVOLUTION-SORT-KEY"

/* Suffixes for column names used to store specialized data */
#define EBSQL_SUFFIX_REVERSE         "reverse"
#define EBSQL_SUFFIX_SORT_KEY        "localized"
#define EBSQL_SUFFIX_PHONE           "phone"
#define EBSQL_SUFFIX_COUNTRY         "country"

/* Track EBookIndexType's in a bit mask  */
#define INDEX_FLAG(type)  (1 << E_BOOK_INDEX_##type)

/* This macro is used to reffer to vcards in statements */
#define EBSQL_VCARD_FRAGMENT(ebsql) \
	((ebsql)->priv->vcard_callback ? \
	 EBSQL_FUNC_FETCH_VCARD " (summary.uid, summary.bdata)" : \
	 "summary.vcard")

/* Signatures for some of the SQLite callbacks which we pass around */
typedef void	(*EbSqlCustomFunc)		(sqlite3_context *context,
						 gint argc,
						 sqlite3_value **argv);
typedef gint	(*EbSqlRowFunc)			(gpointer ref,
						 gint n_cols,
						 gchar **cols,
						 gchar **names);

/* Some forward declarations */
static gboolean		ebsql_init_statements	(EBookSqlite *ebsql,
						 GError **error);
static gboolean		ebsql_insert_contact	(EBookSqlite *ebsql,
						 EbSqlChangeType change_type,
						 EContact *contact,
						 const gchar *original_vcard,
						 const gchar *extra,
						 gboolean replace,
						 GError **error);
static gboolean		ebsql_exec		(EBookSqlite *ebsql,
						 const gchar *stmt,
						 EbSqlRowFunc callback,
						 gpointer data,
						 GCancellable *cancellable,
						 GError **error);

typedef struct {
	EContactField field_id;           /* The EContact field */
	GType         type;               /* The GType (only support string or gboolean) */
	const gchar  *dbname;             /* The key for this field in the sqlite3 table */
	gint          index;              /* Types of searches this field should support (see EBookIndexType) */
	gchar        *aux_table;          /* Name of auxiliary table for this field, for multivalued fields only */
	gchar        *aux_table_symbolic; /* Symolic name of auxiliary table used in queries */
} SummaryField;

struct _EBookSqlitePrivate {

	/* Parameters and settings */
	gchar          *path;            /* Full file name of the file we're operating on (used for hash table entries) */
	gchar          *locale;          /* The current locale */
	gchar          *region_code;     /* Region code (for phone number parsing) */
	gchar          *folderid;        /* The summary table name (configurable, for support of legacy
					  * databases created by EBookSqliteDB) */

	EbSqlVCardCallback  vcard_callback;     /* User callback to fetch vcards instead of storing them */
	EbSqlChangeCallback change_callback;    /* User callback to catch change notifications  */
	gpointer            user_data;          /* Data & Destroy notifier for the above callbacks */
	GDestroyNotify      user_data_destroy;

	/* Summary configuration */
	SummaryField   *summary_fields;
	gint            n_summary_fields;

	GMutex          lock;            /* Main API lock */
	GMutex          updates_lock;    /* Lock used for calls to e_book_sqlite_lock_updates () */
	guint32         in_transaction;  /* Nested transaction counter */
	EbSqlLockType   lock_type;       /* The lock type acquired for the current transaction */
	GCancellable   *cancel;          /* User passed GCancellable, we abort an operation if cancelled */

	ECollator      *collator;        /* The ECollator to create sort keys for any sortable fields */

	/* SQLite resources  */
	sqlite3        *db;
	sqlite3_stmt   *insert_stmt;     /* Insert statement for main summary table */
	sqlite3_stmt   *replace_stmt;    /* Replace statement for main summary table */
	GHashTable     *multi_deletes;   /* Delete statement for each auxiliary table */
	GHashTable     *multi_inserts;   /* Insert statement for each auxiliary table */

	ESource        *source;
};

enum {
	BEFORE_INSERT_CONTACT,
	BEFORE_REMOVE_CONTACT,
	LAST_SIGNAL
};

static guint signals[LAST_SIGNAL];

G_DEFINE_TYPE_WITH_CODE (EBookSqlite, e_book_sqlite, G_TYPE_OBJECT,
			 G_IMPLEMENT_INTERFACE (E_TYPE_EXTENSIBLE, NULL))
G_DEFINE_QUARK (e-book-backend-sqlite-error-quark,
		e_book_sqlite_error)

/* The ColumnInfo struct is used to constant data
 * and dynamically allocated data, the 'type' and
 * 'extra' members are however always constant.
 */
typedef struct {
	gchar       *name;
	const gchar *type;
	const gchar *extra;
	gchar       *index;
} ColumnInfo;

static ColumnInfo main_table_columns[] = {
	{ (gchar *) "folder_id",       "TEXT",      "PRIMARY KEY", NULL },
	{ (gchar *) "version",         "INTEGER",    NULL,         NULL },
	{ (gchar *) "multivalues",     "TEXT",       NULL,         NULL },
	{ (gchar *) "lc_collate",      "TEXT",       NULL,         NULL },
	{ (gchar *) "countrycode",     "VARCHAR(2)", NULL,         NULL },
};

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
static ColumnInfo *
column_info_new (SummaryField *field,
                 const gchar *folderid,
                 const gchar *column_suffix,
                 const gchar *column_type,
                 const gchar *column_extra,
                 const gchar *idx_prefix)
{
	ColumnInfo *info;

	info = g_slice_new0 (ColumnInfo);
	info->type = column_type;
	info->extra = column_extra;

	if (!info->type) {
		if (field->type == G_TYPE_STRING)
			info->type = "TEXT";
		else if (field->type == G_TYPE_BOOLEAN || field->type == E_TYPE_CONTACT_CERT)
			info->type = "INTEGER";
		else if (field->type == E_TYPE_CONTACT_ATTR_LIST)
			info->type = "TEXT";
		else
			g_warn_if_reached ();
	}

	if (field->type == E_TYPE_CONTACT_ATTR_LIST)
		/* Attribute lists are on their own table  */
		info->name = g_strconcat (
			"value",
			column_suffix ? "_" : NULL,
			column_suffix,
			NULL);
	else
		/* Regular fields are named by their 'dbname' */
		info->name = g_strconcat (
			field->dbname,
			column_suffix ? "_" : NULL,
			column_suffix,
			NULL);

	if (idx_prefix)
		info->index = g_strconcat (
			idx_prefix,
			"_", field->dbname,
			"_", folderid,
			NULL);

	return info;
}

static void
column_info_free (ColumnInfo *info)
{
	if (info) {
		g_free (info->name);
		g_free (info->index);
		g_slice_free (ColumnInfo, info);
	}
}

static gint
summary_field_array_index (GArray *array,
                           EContactField field)
{
	gint i;

	for (i = 0; i < array->len; i++) {
		SummaryField *iter = &g_array_index (array, SummaryField, i);
		if (field == iter->field_id)
			return i;
	}

	return -1;
}

static SummaryField *
summary_field_append (GArray *array,
                      const gchar *folderid,
                      EContactField field_id,
                      GError **error)
{
	const gchar *dbname = NULL;
	GType        type = G_TYPE_INVALID;
	gint         idx;
	SummaryField new_field = { 0, };

	if (field_id < 1 || field_id >= E_CONTACT_FIELD_LAST) {
		EBSQL_SET_ERROR (
			error, E_BOOK_SQLITE_ERROR_UNSUPPORTED_FIELD,
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
		dbname = "uid";
		break;
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
		EBSQL_SET_ERROR (
			error, E_BOOK_SQLITE_ERROR_UNSUPPORTED_FIELD,
			_("Contact field “%s” of type “%s” specified in summary, "
			"but only boolean, string and string list field types are supported"),
			e_contact_pretty_name (field_id), g_type_name (type));
		return NULL;
	}

	if (type == E_TYPE_CONTACT_ATTR_LIST) {
		new_field.aux_table = g_strconcat (folderid, "_", dbname, "_list", NULL);
		new_field.aux_table_symbolic = g_strconcat (dbname, "_list", NULL);
	}

	new_field.field_id = field_id;
	new_field.dbname = dbname;
	new_field.type = type;
	new_field.index = 0;
	g_array_append_val (array, new_field);

	return &g_array_index (array, SummaryField, array->len - 1);
}

static gboolean
summary_field_remove (GArray *array,
                      EContactField field)
{
	gint idx;

	idx = summary_field_array_index (array, field);
	if (idx < 0)
		return FALSE;

	g_array_remove_index_fast (array, idx);
	return TRUE;
}

static void
summary_fields_add_indexes (GArray *array,
                            EContactField *indexes,
                            EBookIndexType *index_types,
                            gint n_indexes)
{
	gint i, j;

	for (i = 0; i < array->len; i++) {
		SummaryField *sfield = &g_array_index (array, SummaryField, i);

		for (j = 0; j < n_indexes; j++) {
			if (sfield->field_id == indexes[j])
				sfield->index |= (1 << index_types[j]);

		}
	}
}

static inline gint
summary_field_get_index (EBookSqlite *ebsql,
                         EContactField field_id)
{
	gint i;

	for (i = 0; i < ebsql->priv->n_summary_fields; i++) {
		if (ebsql->priv->summary_fields[i].field_id == field_id)
			return i;
	}

	return -1;
}

static inline SummaryField *
summary_field_get (EBookSqlite *ebsql,
                   EContactField field_id)
{
	gint index;

	index = summary_field_get_index (ebsql, field_id);
	if (index >= 0)
		return &(ebsql->priv->summary_fields[index]);

	return NULL;
}

static GSList *
summary_field_list_columns (SummaryField *field,
                            const gchar *folderid)
{
	GSList *columns = NULL;
	ColumnInfo *info;

	/* Doesn't hurt to verify a bit more here, this shouldn't happen though */
	g_return_val_if_fail (
		field->type == G_TYPE_STRING ||
		field->type == G_TYPE_BOOLEAN ||
		field->type == E_TYPE_CONTACT_CERT ||
		field->type == E_TYPE_CONTACT_ATTR_LIST,
		NULL);

	/* Normal / default column */
	info = column_info_new (
		field, folderid, NULL, NULL,
		(field->field_id == E_CONTACT_UID) ? "PRIMARY KEY" : NULL,
		(field->index & INDEX_FLAG (PREFIX)) != 0 ? "INDEX" : NULL);
	columns = g_slist_prepend (columns, info);

	/* Localized column, for storing sort keys */
	if (field->type == G_TYPE_STRING && (field->index & INDEX_FLAG (SORT_KEY))) {
		info = column_info_new (field, folderid, EBSQL_SUFFIX_SORT_KEY, "TEXT", NULL, "SINDEX");
		columns = g_slist_prepend (columns, info);
	}

	/* Suffix match column */
	if (field->type != G_TYPE_BOOLEAN && field->type != E_TYPE_CONTACT_CERT &&
	    (field->index & INDEX_FLAG (SUFFIX)) != 0) {
		info = column_info_new (field, folderid, EBSQL_SUFFIX_REVERSE, "TEXT", NULL, "RINDEX");
		columns = g_slist_prepend (columns, info);
	}

	/* Phone match columns */
	if (field->type != G_TYPE_BOOLEAN && field->type != E_TYPE_CONTACT_CERT &&
	    (field->index & INDEX_FLAG (PHONE)) != 0) {

		/* One indexed column for storing the national number */
		info = column_info_new (field, folderid, EBSQL_SUFFIX_PHONE, "TEXT", NULL, "PINDEX");
		columns = g_slist_prepend (columns, info);

		/* One integer column for storing the country code */
		info = column_info_new (field, folderid, EBSQL_SUFFIX_COUNTRY, "INTEGER", "DEFAULT 0", NULL);
		columns = g_slist_prepend (columns, info);
	}

	return g_slist_reverse (columns);
}

static void
summary_fields_array_free (SummaryField *fields,
                           gint n_fields)
{
	gint i;

	for (i = 0; i < n_fields; i++) {
		g_free (fields[i].aux_table);
		g_free (fields[i].aux_table_symbolic);
	}

	g_free (fields);
}

/******************************************************
 *        Sharing EBookSqlite instances        *
 ******************************************************/
static GHashTable *db_connections = NULL;
static GMutex dbcon_lock;

static EBookSqlite *
ebsql_ref_from_hash (const gchar *path)
{
	EBookSqlite *ebsql = NULL;

	if (db_connections != NULL) {
		ebsql = g_hash_table_lookup (db_connections, path);
	}

	if (ebsql) {
		EBSQL_NOTE (REF_COUNTS, g_printerr ("EBookSqlite ref count increased from hash table reference\n"));
		g_object_ref (ebsql);
	}

	return ebsql;
}

static void
ebsql_register_to_hash (EBookSqlite *ebsql,
                        const gchar *path)
{
	if (db_connections == NULL)
		db_connections = g_hash_table_new_full (
			(GHashFunc) g_str_hash,
			(GEqualFunc) g_str_equal,
			(GDestroyNotify) g_free,
			(GDestroyNotify) NULL);
	g_hash_table_insert (db_connections, g_strdup (path), ebsql);
}

static void
ebsql_unregister_from_hash (EBookSqlite *ebsql)
{
	EBookSqlitePrivate *priv = ebsql->priv;

	EBSQL_LOCK_MUTEX (&dbcon_lock);
	if (db_connections != NULL) {
		if (priv->path != NULL) {
			g_hash_table_remove (db_connections, priv->path);

			if (g_hash_table_size (db_connections) == 0) {
				g_hash_table_destroy (db_connections);
				db_connections = NULL;
			}

		}
	}
	EBSQL_UNLOCK_MUTEX (&dbcon_lock);
}

/************************************************************
 *                SQLite helper functions                   *
 ************************************************************/

/* For EBSQL_DEBUG_EXPLAIN */
static gint
ebsql_debug_query_plan_cb (gpointer ref,
                           gint n_cols,
                           gchar **cols,
                           gchar **name)
{
	gint i;

	for (i = 0; i < n_cols; i++) {
		if (strcmp (name[i], "detail") == 0) {
			g_printerr ("  PLAN: %s\n", cols[i]);
			break;
		}
	}

	return 0;
}

/* Collect a GList of column names in the main summary table */
static gint
get_columns_cb (gpointer ref,
                gint col,
                gchar **cols,
                gchar **name)
{
	GSList **columns = (GSList **) ref;
	gint i;

	for (i = 0; i < col; i++) {
		if (strcmp (name[i], "name") == 0) {

			/* Keep comparing for the legacy 'bdata' column */
			if (strcmp (cols[i], "vcard") != 0 &&
			    strcmp (cols[i], "bdata") != 0) {
				gchar *column = g_strdup (cols[i]);

				*columns = g_slist_prepend (*columns, column);
			}
			break;
		}
	}
	return 0;
}

/* Collect the first string result */
static gint
get_string_cb (gpointer ref,
               gint col,
               gchar **cols,
               gchar **name)
{
	gchar **ret = ref;

	*ret = g_strdup (cols [0]);

	return 0;
}

/* Collect the first integer result */
static gint
get_int_cb (gpointer ref,
            gint col,
            gchar **cols,
            gchar **name)
{
	gint *ret = ref;

	*ret = cols [0] ? g_ascii_strtoll (cols[0], NULL, 10) : 0;

	return 0;
}

/* Collect the result of a SELECT count(*) statement */
static gint
get_count_cb (gpointer ref,
              gint n_cols,
              gchar **cols,
              gchar **name)
{
	gint64 count = 0;
	gint *ret = ref;
	gint i;

	for (i = 0; i < n_cols; i++) {
		if (name[i] && strncmp (name[i], "count", 5) == 0) {
			count = g_ascii_strtoll (cols[i], NULL, 10);

			break;
		}
	}

	*ret = count;

	return 0;
}

/* Report if there was at least one result */
static gint
get_exists_cb (gpointer ref,
               gint col,
               gchar **cols,
               gchar **name)
{
	gboolean *exists = ref;

	*exists = TRUE;

	return 0;
}

static EbSqlSearchData *
search_data_from_results (gint ncol,
                          gchar **cols,
                          gchar **names)
{
	EbSqlSearchData *data = g_slice_new0 (EbSqlSearchData);
	gint i;
	const gchar *name;

	for (i = 0; i < ncol; i++) {

		if (!names[i] || !cols[i])
			continue;

		name = names[i];
		if (!strncmp (name, "summary.", 8))
			name += 8;

		/* These come through differently depending on the configuration,
		 * search within text is good enough
		 */
		if (!g_ascii_strcasecmp (name, "uid")) {
			data->uid = g_strdup (cols[i]);
		} else if (!g_ascii_strcasecmp (name, "vcard") ||
			   !g_ascii_strncasecmp (name, "fetch_vcard", 11)) {
			data->vcard = g_strdup (cols[i]);
		} else if (!g_ascii_strcasecmp (name, "bdata")) {
			data->extra = g_strdup (cols[i]);
		}
	}

	return data;
}

static gint
collect_full_results_cb (gpointer ref,
                         gint ncol,
                         gchar **cols,
                         gchar **names)
{
	EbSqlSearchData *data;
	GSList **vcard_data = ref;

	data = search_data_from_results (ncol, cols, names);

	*vcard_data = g_slist_prepend (*vcard_data, data);

	return 0;
}

static gint
collect_uid_results_cb (gpointer ref,
                        gint ncol,
                        gchar **cols,
                        gchar **names)
{
	GSList **uids = ref;

	if (cols[0])
		*uids = g_slist_prepend (*uids, g_strdup (cols [0]));

	return 0;
}

static gint
collect_lean_results_cb (gpointer ref,
                         gint ncol,
                         gchar **cols,
                         gchar **names)
{
	GSList **vcard_data = ref;
	EbSqlSearchData *search_data = g_slice_new0 (EbSqlSearchData);
	EContact *contact = e_contact_new ();
	gchar *vcard;
	gint i;

	/* parse through cols, this will be useful if the api starts supporting field restrictions */
	for (i = 0; i < ncol; i++) {
		if (!names[i] || !cols[i])
			continue;

		/* Only UID & REV can be used to create contacts from the summary columns */
		if (!g_ascii_strcasecmp (names[i], "uid")) {
			e_contact_set (contact, E_CONTACT_UID, cols[i]);
			search_data->uid = g_strdup (cols[i]);
		} else if (!g_ascii_strcasecmp (names[i], "Rev")) {
			e_contact_set (contact, E_CONTACT_REV, cols[i]);
		} else if (!g_ascii_strcasecmp (names[i], "bdata")) {
			search_data->extra = g_strdup (cols[i]);
		}
	}

	vcard = e_vcard_to_string (E_VCARD (contact), EVC_FORMAT_VCARD_30);
	search_data->vcard = vcard;
	*vcard_data = g_slist_prepend (*vcard_data, search_data);

	g_object_unref (contact);
	return 0;
}

static void
ebsql_string_append_vprintf (GString *string,
                             const gchar *fmt,
                             va_list args)
{
	gchar *stmt;

	/* Unfortunately, sqlite3_vsnprintf() doesnt tell us
	 * how many bytes it would have needed if it doesnt fit
	 * into the target buffer, so we can't avoid this
	 * really disgusting memory dup.
	 */
	stmt = sqlite3_vmprintf (fmt, args);
	g_string_append (string, stmt);
	sqlite3_free (stmt);
}

static void
ebsql_string_append_printf (GString *string,
                            const gchar *fmt,
                            ...)
{
	va_list args;

	va_start (args, fmt);
	ebsql_string_append_vprintf (string, fmt, args);
	va_end (args);
}

/* Appends an identifier suitable to identify the
 * column to test in the context of a query.
 *
 * The suffix is for special indexed columns (such as
 * reverse values, sort keys, phone numbers, etc).
 */
static void
ebsql_string_append_column (GString *string,
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

static gboolean
ebsql_exec_vprintf (EBookSqlite *ebsql,
                    const gchar *fmt,
                    EbSqlRowFunc callback,
                    gpointer data,
                    GCancellable *cancellable,
                    GError **error,
                    va_list args)
{
	gboolean success;
	gchar *stmt;

	stmt = sqlite3_vmprintf (fmt, args);
	success = ebsql_exec (ebsql, stmt, callback, data, cancellable, error);
	sqlite3_free (stmt);

	return success;
}

static gboolean
ebsql_exec_printf (EBookSqlite *ebsql,
                   const gchar *fmt,
                   EbSqlRowFunc callback,
                   gpointer data,
                   GCancellable *cancellable,
                   GError **error,
                   ...)
{
	gboolean success;
	va_list args;

	va_start (args, error);
	success = ebsql_exec_vprintf (ebsql, fmt, callback, data, cancellable, error, args);
	va_end (args);

	return success;
}

static inline void
ebsql_exec_maybe_debug (EBookSqlite *ebsql,
                        const gchar *stmt)
{
	if (ebsql_debug_flags & EBSQL_DEBUG_EXPLAIN &&
	    strncmp (stmt, "SELECT", 6) == 0) {
		    g_printerr ("EXPLAIN BEGIN\n  STMT: %s\n", stmt);
		    ebsql_exec_printf (ebsql, "EXPLAIN QUERY PLAN %s",
				       ebsql_debug_query_plan_cb,
				       NULL, NULL, NULL, stmt);
		    g_printerr ("EXPLAIN END\n");
	} else {
		EBSQL_NOTE (STATEMENTS, g_printerr ("STMT: %s\n", stmt));
	}
}

static gboolean
ebsql_exec (EBookSqlite *ebsql,
            const gchar *stmt,
            EbSqlRowFunc callback,
            gpointer data,
            GCancellable *cancellable,
            GError **error)
{
	gboolean had_cancel;
	gchar *errmsg = NULL;
	gint ret = -1, retries = 0;
	gint64 t1 = 0, t2;

	/* Debug output for statements and query plans */
	ebsql_exec_maybe_debug (ebsql, stmt);

	/* Just convenience to set the cancellable on an execution
	 * without a transaction, error checking on the cancellable
	 * is done with EBSQL_LOCK_OR_RETURN()
	 */
	if (ebsql->priv->cancel) {
		had_cancel = TRUE;
	} else {
		ebsql->priv->cancel = cancellable;
		had_cancel = FALSE;
	}

	if ((ebsql_debug_flags & EBSQL_DEBUG_TIMING) != 0 &&
	    strncmp (stmt, "EXPLAIN QUERY PLAN ", 19) != 0)
		t1 = g_get_monotonic_time();

	ret = sqlite3_exec (ebsql->priv->db, stmt, callback, data, &errmsg);

	while (ret == SQLITE_BUSY || ret == SQLITE_LOCKED || ret == -1) {
		/* try for ~15 seconds, then give up */
		if (retries > 150)
			break;
		retries++;

		if (errmsg) {
			sqlite3_free (errmsg);
			errmsg = NULL;
		}
		g_thread_yield ();
		g_usleep (100 * 1000); /* Sleep for 100 ms */

		if (t1)
			t1 = g_get_monotonic_time();

		ret = sqlite3_exec (ebsql->priv->db, stmt, callback, data, &errmsg);
	}

	if (!had_cancel)
		ebsql->priv->cancel = NULL;

	if (t1) {
		t2 = g_get_monotonic_time();
		g_printerr ("TIME: %" G_GINT64_FORMAT " ms\n", (t2 - t1) / 1000);
	}
	if (ret != SQLITE_OK) {
		EBSQL_SET_ERROR_FROM_SQLITE (error, ret, errmsg);
		sqlite3_free (errmsg);
		return FALSE;
	}

	if (errmsg)
		sqlite3_free (errmsg);

	return TRUE;
}

static gboolean
ebsql_start_transaction (EBookSqlite *ebsql,
                         EbSqlLockType lock_type,
                         GCancellable *cancel,
                         GError **error)
{
	gboolean success = TRUE;

	g_return_val_if_fail (ebsql != NULL, FALSE);
	g_return_val_if_fail (ebsql->priv != NULL, FALSE);
	g_return_val_if_fail (ebsql->priv->db != NULL, FALSE);

	ebsql->priv->in_transaction++;
	g_return_val_if_fail (ebsql->priv->in_transaction > 0, FALSE);

	if (ebsql->priv->in_transaction == 1) {

		/* No cancellable should be set at transaction start time */
		if (ebsql->priv->cancel) {
			g_warning (
				"Starting a transaction with a cancellable already set. "
				"Clearing previously set cancellable");
			g_clear_object (&ebsql->priv->cancel);
		}

		/* Hold on to the cancel object until the end of the transaction */
		if (cancel)
			ebsql->priv->cancel = g_object_ref (cancel);

		/* It's important to make the distinction between a
		 * transaction which will read or one which will write.
		 *
		 * While it's not well documented, when receiving the SQLITE_BUSY
		 * error status, one can only safely retry at the beginning of
		 * the transaction.
		 *
		 * If a transaction is 'upgraded' to require a writer lock
		 * half way through the transaction and SQLITE_BUSY is returned,
		 * the whole transaction would need to be retried from the beginning.
		 */
		ebsql->priv->lock_type = lock_type;

		switch (lock_type) {
		case EBSQL_LOCK_READ:
			success = ebsql_exec (ebsql, "BEGIN", NULL, NULL, NULL, error);
			break;
		case EBSQL_LOCK_WRITE:
			success = ebsql_exec (ebsql, "BEGIN IMMEDIATE", NULL, NULL, NULL, error);
			break;
		}

	} else {

		/* Warn about cases where where a read transaction might be upgraded */
		if (lock_type == EBSQL_LOCK_WRITE && ebsql->priv->lock_type == EBSQL_LOCK_READ)
			g_warning (
				"A nested transaction wants to write, "
				"but the outermost transaction was started "
				"without a writer lock.");
	}

	return success;
}

static gboolean
ebsql_commit_transaction (EBookSqlite *ebsql,
                          GError **error)
{
	gboolean success = TRUE;

	g_return_val_if_fail (ebsql != NULL, FALSE);
	g_return_val_if_fail (ebsql->priv != NULL, FALSE);
	g_return_val_if_fail (ebsql->priv->db != NULL, FALSE);

	g_return_val_if_fail (ebsql->priv->in_transaction > 0, FALSE);

	ebsql->priv->in_transaction--;

	if (ebsql->priv->in_transaction == 0) {
		success = ebsql_exec (ebsql, "COMMIT", NULL, NULL, NULL, error);

		/* The outermost transaction is finished, let's release
		 * our reference to the user's cancel object here */
		g_clear_object (&ebsql->priv->cancel);
	}

	return success;
}

static gboolean
ebsql_rollback_transaction (EBookSqlite *ebsql,
                            GError **error)
{
	gboolean success = TRUE;

	g_return_val_if_fail (ebsql != NULL, FALSE);
	g_return_val_if_fail (ebsql->priv != NULL, FALSE);
	g_return_val_if_fail (ebsql->priv->db != NULL, FALSE);

	g_return_val_if_fail (ebsql->priv->in_transaction > 0, FALSE);

	ebsql->priv->in_transaction--;

	if (ebsql->priv->in_transaction == 0) {
		success = ebsql_exec (ebsql, "ROLLBACK", NULL, NULL, NULL, error);

		/* The outermost transaction is finished, let's release
		 * our reference to the user's cancel object here */
		g_clear_object (&ebsql->priv->cancel);
	}
	return success;
}

static sqlite3_stmt *
ebsql_prepare_statement (EBookSqlite *ebsql,
                         const gchar *stmt_str,
                         GError **error)
{
	sqlite3_stmt *stmt;
	const gchar *stmt_tail = NULL;
	gint ret;

	ret = sqlite3_prepare_v2 (ebsql->priv->db, stmt_str, strlen (stmt_str), &stmt, &stmt_tail);

	if (ret != SQLITE_OK) {
		const gchar *errmsg = sqlite3_errmsg (ebsql->priv->db);
		EBSQL_SET_ERROR_LITERAL (
			error,
			E_BOOK_SQLITE_ERROR_ENGINE,
			errmsg);
	} else if (stmt == NULL) {
		EBSQL_SET_ERROR_LITERAL (
			error,
			E_BOOK_SQLITE_ERROR_ENGINE,
			"Unknown error preparing SQL statement");
	}

	if (stmt_tail && stmt_tail[0])
		g_warning ("Part of this statement was not parsed: %s", stmt_tail);

	return stmt;
}

/* Convenience for running statements. After successfully
 * binding all parameters, just return with this.
 */
static gboolean
ebsql_complete_statement (EBookSqlite *ebsql,
                          sqlite3_stmt *stmt,
                          gint ret,
                          GError **error)
{
	if (ret == SQLITE_OK)
		ret = sqlite3_step (stmt);

	if (ret != SQLITE_OK && ret != SQLITE_DONE) {
		const gchar *errmsg = sqlite3_errmsg (ebsql->priv->db);
		EBSQL_SET_ERROR_FROM_SQLITE (error, ret, errmsg);
	}

	/* Reset / Clear at the end, regardless of error state */
	sqlite3_reset (stmt);
	sqlite3_clear_bindings (stmt);

	return (ret == SQLITE_OK || ret == SQLITE_DONE);
}

/******************************************************
 *       Functions installed into the SQLite          *
 ******************************************************/

/* Implementation for REGEXP keyword */
static void
ebsql_regexp (sqlite3_context *context,
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

/* Implementation of EBSQL_FUNC_COMPARE_VCARD (fallback for non-summary queries) */
static void
ebsql_compare_vcard (sqlite3_context *context,
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
	 *
	 * This may look extensive, but as the vcard might be resolved by calling a
	 * EbSqlVCardCallback, it's important to reuse this string as much as possible.
	 *
	 * See ebsql_fetch_vcard() for details.
	 */
	vcard = sqlite3_get_auxdata (context, 1);
	if (!vcard) {
		vcard = (const gchar *) sqlite3_value_text (argv[1]);

		if (vcard)
			sqlite3_set_auxdata (context, 1, g_strdup (vcard), g_free);
	}

	/* A NULL vcard can never match */
	if (vcard == NULL || *vcard == '\0') {
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
ebsql_eqphone (sqlite3_context *context,
               gint argc,
               sqlite3_value **argv,
               EPhoneNumberMatch requested_match)
{
	EBookSqlite *ebsql = sqlite3_user_data (context);
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
			input_phone = e_phone_number_from_string (text, ebsql->priv->region_code, NULL);

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
		row_phone = e_phone_number_from_string (text, ebsql->priv->region_code, NULL);

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

/* Exact phone number match function: EBSQL_FUNC_EQPHONE_EXACT */
static void
ebsql_eqphone_exact (sqlite3_context *context,
                     gint argc,
                     sqlite3_value **argv)
{
	ebsql_eqphone (context, argc, argv, E_PHONE_NUMBER_MATCH_EXACT);
}

/* National phone number match function: EBSQL_FUNC_EQPHONE_NATIONAL */
static void
ebsql_eqphone_national (sqlite3_context *context,
                        gint argc,
                        sqlite3_value **argv)
{
	ebsql_eqphone (context, argc, argv, E_PHONE_NUMBER_MATCH_NATIONAL);
}

/* Short phone number match function: EBSQL_FUNC_EQPHONE_SHORT */
static void
ebsql_eqphone_short (sqlite3_context *context,
                     gint argc,
                     sqlite3_value **argv)
{
	ebsql_eqphone (context, argc, argv, E_PHONE_NUMBER_MATCH_SHORT);
}

/* Implementation of EBSQL_FUNC_FETCH_VCARD (fallback for shallow addressbooks) */
static void
ebsql_fetch_vcard (sqlite3_context *context,
                   gint argc,
                   sqlite3_value **argv)
{
	EBookSqlite *ebsql = sqlite3_user_data (context);
	const gchar *uid;
	const gchar *extra;
	gchar *vcard = NULL;

	uid = (const gchar *) sqlite3_value_text (argv[0]);
	extra = (const gchar *) sqlite3_value_text (argv[1]);

	/* Call our delegate to generate the vcard */
	if (ebsql->priv->vcard_callback)
		vcard = ebsql->priv->vcard_callback (
			uid, extra, ebsql->priv->user_data);

	EBSQL_NOTE (
		FETCH_VCARD,
		g_printerr (
			"fetch_vcard (%s, %s) %s",
			uid, extra, vcard ? "Got VCard" : "No VCard"));

	sqlite3_result_text (context, vcard, -1, g_free);
}

typedef struct {
	const gchar     *name;
	EbSqlCustomFunc  func;
	gint             arguments;
} EbSqlCustomFuncTab;

static EbSqlCustomFuncTab ebsql_custom_functions[] = {
	{ "regexp",                    ebsql_regexp,           2 }, /* regexp (expression, column_data) */
	{ EBSQL_FUNC_COMPARE_VCARD,    ebsql_compare_vcard,    2 }, /* compare_vcard (sexp, vcard) */
	{ EBSQL_FUNC_FETCH_VCARD,      ebsql_fetch_vcard,      2 }, /* fetch_vcard (uid, extra) */
	{ EBSQL_FUNC_EQPHONE_EXACT,    ebsql_eqphone_exact,    2 }, /* eqphone_exact (search_input, column_data) */
	{ EBSQL_FUNC_EQPHONE_NATIONAL, ebsql_eqphone_national, 2 }, /* eqphone_national (search_input, column_data) */
	{ EBSQL_FUNC_EQPHONE_SHORT,    ebsql_eqphone_short,    2 }, /* eqphone_national (search_input, column_data) */
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
ebsql_encode_vcard_sort_key (const gchar *sort_key)
{
	EVCard *vcard = e_vcard_new ();
	gchar *base64;
	gchar *encoded;

	/* Encode this otherwise e-vcard messes it up */
	base64 = g_base64_encode ((const guchar *) sort_key, strlen (sort_key));
	e_vcard_append_attribute_with_value (
		vcard,
		e_vcard_attribute_new (NULL, EBSQL_VCARD_SORT_KEY),
		base64);
	encoded = e_vcard_to_string (vcard, EVC_FORMAT_VCARD_30);

	g_free (base64);
	g_object_unref (vcard);

	return encoded;
}

static gchar *
ebsql_decode_vcard_sort_key_from_vcard (EVCard *vcard)
{
	EVCardAttribute *attr;
	GList *values = NULL;
	gchar *sort_key = NULL;
	gchar *base64 = NULL;

	attr = e_vcard_get_attribute (vcard, EBSQL_VCARD_SORT_KEY);
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
ebsql_decode_vcard_sort_key (const gchar *encoded)
{
	EVCard *vcard;
	gchar *sort_key;

	vcard = e_vcard_new_from_string (encoded);
	sort_key = ebsql_decode_vcard_sort_key_from_vcard (vcard);
	g_object_unref (vcard);

	return sort_key;
}

typedef struct {
	EBookSqlite *ebsql;
	EContactField field;
} EbSqlCollData;

static gint
ebsql_fallback_collator (gpointer ref,
                         gint len1,
                         gconstpointer data1,
                         gint len2,
                         gconstpointer data2)
{
	EbSqlCollData *data = (EbSqlCollData *) ref;
	EBookSqlitePrivate *priv;
	EContact *contact1, *contact2;
	const gchar *str1, *str2;
	gchar *key1, *key2;
	gchar *tmp;
	gint result = 0;

	priv = data->ebsql->priv;

	str1 = (const gchar *) data1;
	str2 = (const gchar *) data2;

	/* Construct 2 contacts (we're comparing vcards) */
	contact1 = e_contact_new ();
	contact2 = e_contact_new ();
	e_vcard_construct_full (E_VCARD (contact1), str1, len1, NULL);
	e_vcard_construct_full (E_VCARD (contact2), str2, len2, NULL);

	/* Extract first key */
	key1 = ebsql_decode_vcard_sort_key_from_vcard (E_VCARD (contact1));
	if (!key1) {
		tmp = e_contact_get (contact1, data->field);
		if (tmp)
			key1 = e_collator_generate_key (priv->collator, tmp, NULL);
		g_free (tmp);
	}
	if (!key1)
		key1 = g_strdup ("");

	/* Extract second key */
	key2 = ebsql_decode_vcard_sort_key_from_vcard (E_VCARD (contact2));
	if (!key2) {
		tmp = e_contact_get (contact2, data->field);
		if (tmp)
			key2 = e_collator_generate_key (priv->collator, tmp, NULL);
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

static EbSqlCollData *
ebsql_coll_data_new (EBookSqlite *ebsql,
                     EContactField field)
{
	EbSqlCollData *data = g_slice_new (EbSqlCollData);

	data->ebsql = ebsql;
	data->field = field;

	return data;
}

static void
ebsql_coll_data_free (EbSqlCollData *data)
{
	if (data)
		g_slice_free (EbSqlCollData, data);
}

/* COLLATE functions are generated on demand only */
static void
ebsql_generate_collator (gpointer ref,
                         sqlite3 *db,
                         gint eTextRep,
                         const gchar *coll_name)
{
	EBookSqlite *ebsql = (EBookSqlite *) ref;
	EbSqlCollData *data;
	EContactField field;
	const gchar *field_name;

	field_name = coll_name + strlen (EBSQL_COLLATE_PREFIX);
	field = e_contact_field_id (field_name);

	/* This should be caught before reaching here, just an extra check */
	if (field == 0 || field >= E_CONTACT_FIELD_LAST ||
	    e_contact_field_type (field) != G_TYPE_STRING) {
		g_warning ("Specified collation on invalid contact field");
		return;
	}

	data = ebsql_coll_data_new (ebsql, field);
	sqlite3_create_collation_v2 (
		db, coll_name, SQLITE_UTF8,
		data, ebsql_fallback_collator,
		(GDestroyNotify) ebsql_coll_data_free);
}

/**********************************************************
 *        Cancel long operations with GCancellable        *
 **********************************************************/
static gint
ebsql_check_cancel (gpointer ref)
{
	EBookSqlite *ebsql = (EBookSqlite *) ref;

	if (ebsql->priv->cancel &&
	    g_cancellable_is_cancelled (ebsql->priv->cancel)) {
		EBSQL_NOTE (
			CANCEL,
			g_printerr ("CANCEL: An operation was cancelled\n"));
		return -1;
	}

	return 0;
}

/**********************************************************
 *                  Database Initialization               *
 **********************************************************/
static inline gint
main_table_index_by_name (const gchar *name)
{
	gint i;

	for (i = 0; i < G_N_ELEMENTS (main_table_columns); i++) {
		if (g_strcmp0 (name, main_table_columns[i].name) == 0)
			return i;
	}

	return -1;
}

static gint
check_main_table_columns (gpointer data,
                          gint n_cols,
                          gchar **cols,
                          gchar **name)
{
	guint *columns_mask = (guint *) data;
	gint i;

	for (i = 0; i < n_cols; i++) {

		if (g_strcmp0 (name[i], "name") == 0) {
			gint idx = main_table_index_by_name (cols[i]);

			if (idx >= 0)
				*columns_mask |= (1 << idx);

			break;
		}
	}

	return 0;
}

static gboolean
ebsql_init_sqlite (EBookSqlite *ebsql,
                   const gchar *filename,
                   GError **error)
{
	gint ret, i;

	e_sqlite3_vfs_init ();

	ret = sqlite3_open (filename, &ebsql->priv->db);

	/* Handle GCancellable */
	sqlite3_progress_handler (
		ebsql->priv->db,
		EBSQL_CANCEL_BATCH_SIZE,
		ebsql_check_cancel,
		ebsql);

	/* Install our custom functions */
	for (i = 0; ret == SQLITE_OK && i < G_N_ELEMENTS (ebsql_custom_functions); i++)
		ret = sqlite3_create_function (
			ebsql->priv->db,
			ebsql_custom_functions[i].name,
			ebsql_custom_functions[i].arguments,
			SQLITE_UTF8, ebsql,
			ebsql_custom_functions[i].func,
			NULL, NULL);

	/* Fallback COLLATE implementations generated on demand */
	if (ret == SQLITE_OK)
		ret = sqlite3_collation_needed (
			ebsql->priv->db, ebsql, ebsql_generate_collator);

	if (ret != SQLITE_OK) {
		if (!ebsql->priv->db) {
			EBSQL_SET_ERROR_LITERAL (
				error,
				E_BOOK_SQLITE_ERROR_LOAD,
				_("Insufficient memory"));
		} else {
			const gchar *errmsg = sqlite3_errmsg (ebsql->priv->db);

			EBSQL_SET_ERROR (
				error,
				E_BOOK_SQLITE_ERROR_ENGINE,
				"Can't open database %s: %s\n",
				filename, errmsg);
			sqlite3_close (ebsql->priv->db);
		}
		return FALSE;
	}

	ebsql_exec (ebsql, "ATTACH DATABASE ':memory:' AS mem", NULL, NULL, NULL, NULL);
	ebsql_exec (ebsql, "PRAGMA foreign_keys = ON",          NULL, NULL, NULL, NULL);
	ebsql_exec (ebsql, "PRAGMA case_sensitive_like = ON",   NULL, NULL, NULL, NULL);

	return TRUE;
}

static inline void
format_column_declaration (GString *string,
                           ColumnInfo *info)
{
	g_string_append (string, info->name);
	g_string_append_c (string, ' ');

	g_string_append (string, info->type);

	if (info->extra) {
		g_string_append_c (string, ' ');
		g_string_append (string, info->extra);
	}
}

static inline gboolean
ensure_column_index (EBookSqlite *ebsql,
                     const gchar *table,
                     ColumnInfo *info,
                     GError **error)
{
	if (!info->index)
		return TRUE;

	return ebsql_exec_printf (
		ebsql,
		"CREATE INDEX IF NOT EXISTS %Q ON %Q (%s)",
		NULL, NULL, NULL, error,
		info->index, table, info->name);
}

/* Called with the lock held and inside a transaction */
static gboolean
ebsql_resolve_folderid (EBookSqlite *ebsql,
                        gint *previous_schema,
                        gint *already_exists,
                        GError **error)
{
	gint n_folders = 0;
	gint version = 0;
	gchar *loaded_folder_id = NULL;
	gboolean success;

	success = ebsql_exec (
		ebsql, "SELECT count(*) FROM sqlite_master "
		"WHERE type='table' AND name='folders';",
		get_count_cb, &n_folders, NULL, error);

	if (success && n_folders > 1) {
		EBSQL_SET_ERROR_LITERAL (
			error,
			E_BOOK_SQLITE_ERROR_LOAD,
			_("Cannot upgrade contacts database from a legacy "
			"database with more than one addressbook. "
			"Delete one of the entries in the “folders” table first."));
		success = FALSE;
	}

	if (success && n_folders == 1)
		success = ebsql_exec (
			ebsql, "SELECT folder_id FROM folders LIMIT 1",
			get_string_cb, &loaded_folder_id, NULL, error);

	if (success && n_folders == 1)
		success = ebsql_exec (
			ebsql, "SELECT version FROM folders LIMIT 1",
			get_int_cb, &version, NULL, error);

	if (success && n_folders == 1) {
		g_free (ebsql->priv->folderid);
		ebsql->priv->folderid = loaded_folder_id;
	} else {
		g_free (loaded_folder_id);
	}

	if (n_folders == 1)
		*already_exists = TRUE;
	else
		*already_exists = FALSE;

	EBSQL_NOTE (
		SCHEMA,
		g_printerr (
			"SCHEMA: main folder id resolved as '%s', "
			"already existing tables: %d loaded version: %d (%s)\n",
			ebsql->priv->folderid, n_folders, version,
			success ? "success" : "failed"));

	*previous_schema = version;

	return success;
}

/* Called with the lock held and inside a transaction */
static gboolean
ebsql_init_folders (EBookSqlite *ebsql,
                    gint previous_schema,
                    GError **error)
{
	GString *string;
	guint existing_columns_mask = 0, i;
	gboolean success;

	string = g_string_sized_new (COLUMN_DEFINITION_BYTES * G_N_ELEMENTS (main_table_columns));
	g_string_append (string, "CREATE TABLE IF NOT EXISTS folders (");
	for (i = 0; i < G_N_ELEMENTS (main_table_columns); i++) {

		if (i > 0)
			g_string_append (string, ", ");

		format_column_declaration (string, &(main_table_columns[i]));
	}
	g_string_append_c (string, ')');

	/* Create main folders table */
	success = ebsql_exec (ebsql, string->str, NULL, NULL, NULL, error);
	g_string_free (string, TRUE);

	/* Check which columns in the main table already exist */
	if (success)
		success = ebsql_exec (
			ebsql, "PRAGMA table_info (folders)",
			check_main_table_columns, &existing_columns_mask,
			NULL, error);

	/* Add columns which may be missing */
	for (i = 0; success && i < G_N_ELEMENTS (main_table_columns); i++) {
		ColumnInfo *info = &(main_table_columns[i]);

		if ((existing_columns_mask & (1 << i)) != 0)
			continue;

		success = ebsql_exec_printf (
			ebsql, "ALTER TABLE folders ADD COLUMN %s %s %s",
			NULL, NULL, NULL, error, info->name, info->type,
			info->extra ? info->extra : "");
	}

	/* Special case upgrade for schema versions 3 & 4.
	 * 
	 * Drops the reverse_multivalues column.
	 */
	if (success && previous_schema >= 3 && previous_schema < 5) {

		success = ebsql_exec (
			ebsql,
			"UPDATE folders SET "
				"multivalues = REPLACE(RTRIM(REPLACE("
					"multivalues || ':', ':', "
					"CASE reverse_multivalues "
						"WHEN 0 THEN ';prefix ' "
						"ELSE ';prefix;suffix ' "
					"END)), ' ', ':'), "
				"reverse_multivalues = NULL",
			NULL, NULL, NULL, error);
	}

	/* Finish the eventual upgrade by storing the current schema version.
	 */
	if (success && previous_schema >= 1 && previous_schema < FOLDER_VERSION)
		success = ebsql_exec_printf (
			ebsql, "UPDATE folders SET version = %d",
			NULL, NULL, NULL, error, FOLDER_VERSION);

	EBSQL_NOTE (
		SCHEMA,
		g_printerr (
			"SCHEMA: Initialized main folders table (%s)\n",
			success ? "success" : "failed"));

	return success;
}

/* Called with the lock held and inside a transaction */
static gboolean
ebsql_init_keys (EBookSqlite *ebsql,
                 GError **error)
{
	gboolean success;

	/* Create a child table to store key/value pairs for a folder. */
	success = ebsql_exec (
		ebsql,
		"CREATE TABLE IF NOT EXISTS keys ("
		" key TEXT PRIMARY KEY,"
		" value TEXT,"
		" folder_id TEXT REFERENCES folders)",
		NULL, NULL, NULL, error);

	/* Add an index on the keys */
	if (success)
		success = ebsql_exec (
			ebsql,
			"CREATE INDEX IF NOT EXISTS keysindex ON keys (folder_id)",
			NULL, NULL, NULL, error);

	EBSQL_NOTE (
		SCHEMA,
		g_printerr (
			"SCHEMA: Initialized keys table (%s)\n",
			success ? "success" : "failed"));

	return success;
}

static gchar *
format_multivalues (EBookSqlite *ebsql)
{
	gint i;
	GString *string;
	gboolean first = TRUE;

	string = g_string_new (NULL);

	for (i = 0; i < ebsql->priv->n_summary_fields; i++) {
		if (ebsql->priv->summary_fields[i].type == E_TYPE_CONTACT_ATTR_LIST) {
			if (first)
				first = FALSE;
			else
				g_string_append_c (string, ':');

			g_string_append (string, ebsql->priv->summary_fields[i].dbname);

			/* E_BOOK_INDEX_SORT_KEY is not supported in the multivalue fields */
			if ((ebsql->priv->summary_fields[i].index & INDEX_FLAG (PREFIX)) != 0)
				g_string_append (string, ";prefix");
			if ((ebsql->priv->summary_fields[i].index & INDEX_FLAG (SUFFIX)) != 0)
				g_string_append (string, ";suffix");
			if ((ebsql->priv->summary_fields[i].index & INDEX_FLAG (PHONE)) != 0)
				g_string_append (string, ";phone");
		}
	}

	return g_string_free (string, string->len == 0);
}

/* Called with the lock held and inside a transaction */
static gboolean
ebsql_add_folder (EBookSqlite *ebsql,
                  GError **error)
{
	gboolean success;
	gchar *multivalues;
	const gchar *lc_collate;

	multivalues = format_multivalues (ebsql);
	lc_collate = setlocale (LC_COLLATE, NULL);

	success = ebsql_exec_printf (
		ebsql,
		"INSERT OR IGNORE INTO folders"
		" ( folder_id, version, multivalues, lc_collate ) "
		"VALUES ( %Q, %d, %Q, %Q ) ",
		NULL, NULL, NULL, error,
		ebsql->priv->folderid, FOLDER_VERSION, multivalues, lc_collate);

	g_free (multivalues);

	EBSQL_NOTE (
		SCHEMA,
		g_printerr (
			"SCHEMA: Added '%s' entry to main folder (%s)\n",
			ebsql->priv->folderid, success ? "success" : "failed"));

	return success;
}

static gboolean
ebsql_email_list_exists (EBookSqlite *ebsql)
{
	gint n_tables = 0;
	gboolean success;

	success = ebsql_exec_printf (
		ebsql, "SELECT count(*) FROM sqlite_master WHERE type='table' AND name='%q_email_list';",
		get_count_cb, &n_tables, NULL, NULL,
		ebsql->priv->folderid);

	if (!success)
		return FALSE;

	return n_tables == 1;
}

/* Called with the lock held and inside a transaction */
static gboolean
ebsql_introspect_summary (EBookSqlite *ebsql,
                          gint previous_schema,
                          GSList **introspected_columns,
                          GError **error)
{
	gboolean success;
	GSList *summary_columns = NULL, *l;
	GArray *summary_fields = NULL;
	gchar *multivalues = NULL;
	gint i, j;

	success = ebsql_exec_printf (
		ebsql, "PRAGMA table_info (%Q);",
		get_columns_cb, &summary_columns, NULL, error,
		ebsql->priv->folderid);

	if (!success)
		goto introspect_summary_finish;

	summary_columns = g_slist_reverse (summary_columns);
	summary_fields = g_array_new (FALSE, FALSE, sizeof (SummaryField));

	/* Introspect the normal summary fields */
	for (l = summary_columns; l; l = l->next) {
		EContactField field_id;
		const gchar *col = l->data;
		gchar *p;
		gint computed = 0;
		gchar *freeme = NULL;

		/* Note that we don't have any way to introspect
		 * E_BOOK_INDEX_PREFIX, this is not important because if
		 * the prefix index is specified, it will be created
		 * the first time the SQLite tables are created, so
		 * it's not important to ensure prefix indexes after
		 * introspecting the summary.
		 */

		/* Check if we're parsing a reverse field */
		if ((p = strstr (col, "_" EBSQL_SUFFIX_REVERSE)) != NULL) {
			computed = INDEX_FLAG (SUFFIX);
			freeme = g_strndup (col, p - col);
			col = freeme;
		} else if ((p = strstr (col, "_" EBSQL_SUFFIX_PHONE)) != NULL) {
			computed = INDEX_FLAG (PHONE);
			freeme = g_strndup (col, p - col);
			col = freeme;
		} else if ((p = strstr (col, "_" EBSQL_SUFFIX_COUNTRY)) != NULL) {
			computed = INDEX_FLAG (PHONE);
			freeme = g_strndup (col, p - col);
			col = freeme;
		} else if ((p = strstr (col, "_" EBSQL_SUFFIX_SORT_KEY)) != NULL) {
			computed = INDEX_FLAG (SORT_KEY);
			freeme = g_strndup (col, p - col);
			col = freeme;
		}

		/* First check exception fields */
		if (g_ascii_strcasecmp (col, "uid") == 0)
			field_id = E_CONTACT_UID;
		else if (g_ascii_strcasecmp (col, "is_list") == 0)
			field_id = E_CONTACT_IS_LIST;
		else
			field_id = e_contact_field_id (col);

		/* Check for parse error */
		if (field_id == 0) {
			EBSQL_SET_ERROR (
				error,
				E_BOOK_SQLITE_ERROR_UNSUPPORTED_FIELD,
				_("Error introspecting unknown summary field “%s”"),
				col);
			success = FALSE;
			g_free (freeme);
			break;
		}

		/* Computed columns are always declared after the normal columns,
		 * if a reverse field is encountered we need to set the suffix
		 * index on the coresponding summary field
		 */
		if (computed) {
			gint field_idx;
			SummaryField *iter;

			field_idx = summary_field_array_index (summary_fields, field_id);
			if (field_idx >= 0) {
				iter = &g_array_index (summary_fields, SummaryField, field_idx);
				iter->index |= computed;
			}

		} else {
			summary_field_append (
				summary_fields, ebsql->priv->folderid,
				field_id, NULL);
		}

		g_free (freeme);
	}

	if (!success)
		goto introspect_summary_finish;

	/* Introspect the multivalied summary fields */
	success = ebsql_exec_printf (
		ebsql,
		"SELECT multivalues FROM folders "
		"WHERE folder_id = %Q",
		get_string_cb, &multivalues, NULL, error,
		ebsql->priv->folderid);

	if (!success)
		goto introspect_summary_finish;

	if (!multivalues || !*multivalues) {
		g_free (multivalues);
		multivalues = NULL;

		/* The migration from a previous version didn't store this default multivalue
		   reference, thus the next backend open (not the immediate one after migration),
		   didn't know about this table, which has a FOREIGN KEY constraint, thus an item
		   delete caused a 'FOREIGN KEY constraint failed' error.
		*/
		if (ebsql_email_list_exists (ebsql))
			multivalues = g_strdup ("email;prefix");
	}

	if (multivalues) {
		gchar **fields = g_strsplit (multivalues, ":", 0);

		for (i = 0; fields[i] != NULL; i++) {
			EContactField field_id;
			SummaryField *iter;
			gchar **params;

			params = g_strsplit (fields[i], ";", 0);
			field_id = e_contact_field_id (params[0]);
			iter = summary_field_append (
				summary_fields,
				ebsql->priv->folderid,
				field_id, NULL);

			if (iter) {
				for (j = 1; params[j]; ++j) {
					/* Sort keys not supported for multivalued fields */
					if (strcmp (params[j], "prefix") == 0) {
						iter->index |= INDEX_FLAG (PREFIX);
					} else if (strcmp (params[j], "suffix") == 0) {
						iter->index |= INDEX_FLAG (SUFFIX);
					} else if (strcmp (params[j], "phone") == 0) {
						iter->index |= INDEX_FLAG (PHONE);
					}
				}
			}

			g_strfreev (params);
		}

		g_strfreev (fields);
	}

	/* HARD CODE UP AHEAD
	 *
	 * Now we're finished introspecting, if the summary is from a previous version,
	 * we need to add any summary fields which we're added to the default summary
	 * since the schema version which was introduced here
	 */
	if (previous_schema >= 1) {
		SummaryField *summary_field;

		if (previous_schema < 8) {

			/* We used to keep 4 email fields in the summary, before we supported
			 * the multivaliued E_CONTACT_EMAIL... convert the old summary to use
			 * the multivaliued field instead.
			 */
			if (summary_field_array_index (summary_fields, E_CONTACT_EMAIL_1) >= 0 &&
			    summary_field_array_index (summary_fields, E_CONTACT_EMAIL_2) >= 0 &&
			    summary_field_array_index (summary_fields, E_CONTACT_EMAIL_3) >= 0 &&
			    summary_field_array_index (summary_fields, E_CONTACT_EMAIL_4) >= 0) {

				summary_field_remove (summary_fields, E_CONTACT_EMAIL_1);
				summary_field_remove (summary_fields, E_CONTACT_EMAIL_2);
				summary_field_remove (summary_fields, E_CONTACT_EMAIL_3);
				summary_field_remove (summary_fields, E_CONTACT_EMAIL_4);

				summary_field = summary_field_append (
					summary_fields,
					ebsql->priv->folderid,
					E_CONTACT_EMAIL, NULL);
				summary_field->index |= INDEX_FLAG (PREFIX);
			}

			/* Regardless of whether it was a default summary or not, add the sort
			 * keys to anything less than Schema 8 (as long as those fields are at least
			 * in the summary)
			 */
			if ((i = summary_field_array_index (summary_fields, E_CONTACT_FILE_AS)) >= 0) {
				summary_field = &g_array_index (summary_fields, SummaryField, i);
				summary_field->index |= INDEX_FLAG (SORT_KEY);
			}

			if ((i = summary_field_array_index (summary_fields, E_CONTACT_GIVEN_NAME)) >= 0) {
				summary_field = &g_array_index (summary_fields, SummaryField, i);
				summary_field->index |= INDEX_FLAG (SORT_KEY);
			}

			if ((i = summary_field_array_index (summary_fields, E_CONTACT_FAMILY_NAME)) >= 0) {
				summary_field = &g_array_index (summary_fields, SummaryField, i);
				summary_field->index |= INDEX_FLAG (SORT_KEY);
			}
		}

		if (previous_schema < 9) {
			if (summary_field_array_index (summary_fields, E_CONTACT_X509_CERT) < 0) {
				summary_field_append (summary_fields, ebsql->priv->folderid,
						      E_CONTACT_X509_CERT, NULL);
			}
		}

		if (previous_schema < 10) {
			if ((i = summary_field_array_index (summary_fields, E_CONTACT_NICKNAME)) >= 0) {
				summary_field = &g_array_index (summary_fields, SummaryField, i);
				summary_field->index |= INDEX_FLAG (PREFIX);
			}

			if ((i = summary_field_array_index (summary_fields, E_CONTACT_FILE_AS)) >= 0) {
				summary_field = &g_array_index (summary_fields, SummaryField, i);
				summary_field->index |= INDEX_FLAG (PREFIX);
			}

			if ((i = summary_field_array_index (summary_fields, E_CONTACT_GIVEN_NAME)) >= 0) {
				summary_field = &g_array_index (summary_fields, SummaryField, i);
				summary_field->index |= INDEX_FLAG (PREFIX);
			}

			if ((i = summary_field_array_index (summary_fields, E_CONTACT_FAMILY_NAME)) >= 0) {
				summary_field = &g_array_index (summary_fields, SummaryField, i);
				summary_field->index |= INDEX_FLAG (PREFIX);
			}

		}

		if (previous_schema < 12) {
			if (summary_field_array_index (summary_fields, E_CONTACT_PGP_CERT) < 0) {
				summary_field_append (summary_fields, ebsql->priv->folderid,
						      E_CONTACT_PGP_CERT, NULL);
			}
		}
	}

 introspect_summary_finish:

	/* Apply the introspected summary fields */
	if (success) {
		summary_fields_array_free (
			ebsql->priv->summary_fields,
			ebsql->priv->n_summary_fields);

		ebsql->priv->n_summary_fields = summary_fields->len;
		ebsql->priv->summary_fields = (SummaryField *) g_array_free (summary_fields, FALSE);

		*introspected_columns = summary_columns;
	} else if (summary_fields) {
		gint n_fields;
		SummaryField *fields;

		/* Properly free the array */
		n_fields = summary_fields->len;
		fields = (SummaryField *) g_array_free (summary_fields, FALSE);
		summary_fields_array_free (fields, n_fields);

		g_slist_free_full (summary_columns, (GDestroyNotify) g_free);
	}

	g_free (multivalues);

	EBSQL_NOTE (
		SCHEMA,
		g_printerr (
			"SCHEMA: Introspected summary (%s)\n",
			success ? "success" : "failed"));

	return success;
}

/* Called with the lock held and inside a transaction */
static gboolean
ebsql_init_contacts (EBookSqlite *ebsql,
                     GSList *introspected_columns,
                     GError **error)
{
	gint i;
	gboolean success = TRUE;
	GString *string;
	GSList *summary_columns = NULL, *l;

	/* Get a list of all columns and indexes which should be present
	 * in the main summary table */
	for (i = 0; i < ebsql->priv->n_summary_fields; i++) {
		SummaryField *field = &(ebsql->priv->summary_fields[i]);

		if (field->type != E_TYPE_CONTACT_ATTR_LIST) {
			l = summary_field_list_columns (field, ebsql->priv->folderid);
			summary_columns = g_slist_concat (summary_columns, l);
		}
	}

	/* Create the main contacts table for this folder
	 */
	string = g_string_sized_new (32 * g_slist_length (summary_columns));
	g_string_append (string, "CREATE TABLE IF NOT EXISTS %Q (");

	for (l = summary_columns; l; l = l->next) {
		ColumnInfo *info = l->data;

		if (l != summary_columns)
			g_string_append (string, ", ");

		format_column_declaration (string, info);
	}
	g_string_append (string, ", vcard TEXT, bdata TEXT)");

	success = ebsql_exec_printf (
		ebsql, string->str,
		NULL, NULL, NULL, error,
		ebsql->priv->folderid);

	g_string_free (string, TRUE);

	/* If we introspected something, let's first adjust the contacts table
	 * so that it includes the right columns */
	if (introspected_columns) {

		/* Add any missing columns which are in the summary fields but
		 * not found in the contacts table
		 */
		for (l = summary_columns; success && l; l = l->next) {
			ColumnInfo *info = l->data;

			if (g_slist_find_custom (introspected_columns,
						 info->name, (GCompareFunc) g_ascii_strcasecmp))
				continue;

			success = ebsql_exec_printf (
				ebsql,
				"ALTER TABLE %Q ADD COLUMN %s %s %s",
				NULL, NULL, NULL, error,
				ebsql->priv->folderid,
				info->name, info->type,
				info->extra ? info->extra : "");
		}
	}

	/* Add indexes to columns in the main contacts table
	 */
	for (l = summary_columns; success && l; l = l->next) {
		ColumnInfo *info = l->data;

		success = ensure_column_index (ebsql, ebsql->priv->folderid, info, error);
	}

	g_slist_free_full (summary_columns, (GDestroyNotify) column_info_free);

	EBSQL_NOTE (
		SCHEMA,
		g_printerr (
			"SCHEMA: Initialized summary table '%s' (%s)\n",
			ebsql->priv->folderid, success ? "success" : "failed"));

	return success;
}

/* Called with the lock held and inside a transaction */
static gboolean
ebsql_init_aux_tables (EBookSqlite *ebsql,
                       gint previous_schema,
                       GError **error)
{
	GString *string;
	gboolean success = TRUE;
	GSList *aux_columns = NULL, *l;
	gchar *tmp;
	gint i;

	/* Drop the general 'folder_id_lists' table which was used prior to
	 * version 8 of the schema
	 */
	if (previous_schema >= 1 && previous_schema < 8) {
		tmp = g_strconcat (ebsql->priv->folderid, "_lists", NULL);
		success = ebsql_exec_printf (
			ebsql, "DROP TABLE IF EXISTS %Q",
			NULL, NULL, NULL, error, tmp);
		g_free (tmp);
	}

	for (i = 0; success && i < ebsql->priv->n_summary_fields; i++) {
		SummaryField *field = &(ebsql->priv->summary_fields[i]);

		if (field->type != E_TYPE_CONTACT_ATTR_LIST)
			continue;

		aux_columns = summary_field_list_columns (field, ebsql->priv->folderid);

		/* Create the auxiliary table for this multi valued field */
		string = g_string_sized_new (
			COLUMN_DEFINITION_BYTES * 3 +
			COLUMN_DEFINITION_BYTES * g_slist_length (aux_columns));

		g_string_append (string, "CREATE TABLE IF NOT EXISTS %Q (uid TEXT NOT NULL REFERENCES %Q (uid)");
		for (l = aux_columns; l; l = l->next) {
			ColumnInfo *info = l->data;

			g_string_append (string, ", ");
			format_column_declaration (string, info);
		}
		g_string_append_c (string, ')');

		success = ebsql_exec_printf (
			ebsql, string->str, NULL, NULL, NULL, error,
			field->aux_table, ebsql->priv->folderid);
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
			tmp = g_strconcat (
				"UID_INDEX",
				"_", field->dbname,
				"_", ebsql->priv->folderid,
				NULL);
			ebsql_exec_printf (
				ebsql,
				"CREATE INDEX IF NOT EXISTS %Q ON %Q (%s)",
				NULL, NULL, NULL, error,
				tmp, field->aux_table, "uid");
			g_free (tmp);
		}

		/* Add indexes to columns in this auxiliary table
		 */
		for (l = aux_columns; success && l; l = l->next) {
			ColumnInfo *info = l->data;

			success = ensure_column_index (ebsql, field->aux_table, info, error);
		}

		g_slist_free_full (aux_columns, (GDestroyNotify) column_info_free);

		EBSQL_NOTE (
			SCHEMA,
			g_printerr (
				"SCHEMA: Initialized auxiliary table '%s'\n",
				field->aux_table));
	}

	if (success) {
		gchar *multivalues;

		multivalues = format_multivalues (ebsql);

		success = ebsql_exec_printf (
			ebsql,
			"UPDATE folders SET multivalues=%Q WHERE folder_id=%Q",
			NULL, NULL, NULL, error,
			multivalues, ebsql->priv->folderid);

		g_free (multivalues);
	}

	EBSQL_NOTE (
		SCHEMA,
		g_printerr (
			"SCHEMA: Initialized auxiliary tables (%s)\n",
			success ? "success" : "failed"));

	return success;
}

static gboolean
ebsql_upgrade_one (EBookSqlite *ebsql,
                   EbSqlChangeType change_type,
                   EbSqlSearchData *result,
                   GError **error)
{
	EContact *contact = NULL;
	gboolean success;

	/* It can be we're opening a light summary which was created without
	 * storing the vcards, such as was used in EDS versions 3.2 to 3.6.
	 *
	 * In this case we just want to skip the contacts we can't load
	 * and leave them as is in the SQLite, they will be added from
	 * the old BDB in the case of a migration anyway.
	 */
	if (result->vcard)
		contact = e_contact_new_from_vcard_with_uid (result->vcard, result->uid);

	if (contact == NULL)
		return TRUE;

	success = ebsql_insert_contact (
		ebsql, change_type, contact,
		result->vcard, result->extra,
		TRUE, error);

	g_object_unref (contact);

	return success;
}

/* Called with the lock held and inside a transaction */
static gboolean
ebsql_upgrade (EBookSqlite *ebsql,
               EbSqlChangeType change_type,
               GError **error)
{
	gchar *uid = NULL;
	gint n_results;
	gboolean success = TRUE;

	do {
		GSList *batch = NULL, *l;
		EbSqlSearchData *result = NULL;

		if (uid == NULL) {
			success = ebsql_exec_printf (
				ebsql,
				"SELECT summary.uid, %s, summary.bdata FROM %Q AS summary "
				"ORDER BY summary.uid ASC LIMIT %d",
				collect_full_results_cb, &batch, NULL, error,
				EBSQL_VCARD_FRAGMENT (ebsql),
				ebsql->priv->folderid, EBSQL_UPGRADE_BATCH_SIZE);
		} else {
			success = ebsql_exec_printf (
				ebsql,
				"SELECT summary.uid, %s, summary.bdata FROM %Q AS summary "
				"WHERE summary.uid > %Q "
				"ORDER BY summary.uid ASC LIMIT %d",
				collect_full_results_cb, &batch, NULL, error,
				EBSQL_VCARD_FRAGMENT (ebsql),
				ebsql->priv->folderid, uid, EBSQL_UPGRADE_BATCH_SIZE);
		}

		/* Reverse the list, we want to walk through it forwards */
		batch = g_slist_reverse (batch);
		for (l = batch; success && l; l = l->next) {
			result = l->data;
			success = ebsql_upgrade_one (
				ebsql,
				change_type,
				result,
				error);
		}

		/* result is now the last one in the list */
		if (result) {
			g_free (uid);
			uid = result->uid;
			result->uid = NULL;
		}

		n_results = g_slist_length (batch);
		g_slist_free_full (batch, (GDestroyNotify) e_book_sqlite_search_data_free);

	} while (success && n_results == EBSQL_UPGRADE_BATCH_SIZE);

	g_free (uid);

	/* Store the new locale & country code */
	if (success)
		success = ebsql_exec_printf (
			ebsql, "UPDATE folders SET countrycode = %Q WHERE folder_id = %Q",
			NULL, NULL, NULL, error,
			ebsql->priv->region_code, ebsql->priv->folderid);

	if (success)
		success = ebsql_exec_printf (
			ebsql, "UPDATE folders SET lc_collate = %Q WHERE folder_id = %Q",
			NULL, NULL, NULL, error,
			ebsql->priv->locale, ebsql->priv->folderid);

	return success;
}

static gboolean
ebsql_set_locale_internal (EBookSqlite *ebsql,
                           const gchar *locale,
                           GError **error)
{
	EBookSqlitePrivate *priv = ebsql->priv;
	ECollator *collator;

	g_return_val_if_fail (locale && locale[0], FALSE);

	if (g_strcmp0 (priv->locale, locale) != 0) {
		gchar *country_code = NULL;

		collator = e_collator_new_interpret_country (
			locale, &country_code, error);
		if (collator == NULL)
			return FALSE;

		/* Assign region code parsed from the locale by ICU */
		g_free (priv->region_code);
		priv->region_code = country_code;

		/* Assign locale */
		g_free (priv->locale);
		priv->locale = g_strdup (locale);

		/* Assign collator */
		if (ebsql->priv->collator)
			e_collator_unref (ebsql->priv->collator);
		ebsql->priv->collator = collator;
	}

	return TRUE;
}

/* Called with the lock held and inside a transaction */
static gboolean
ebsql_init_legacy_keys (EBookSqlite *ebsql,
                        gint previous_schema,
                        GError **error)
{
	gboolean success = TRUE;

	/* Schema 8 is when we moved from EBookSqlite */
	if (previous_schema >= 1 && previous_schema < 8) {
		gint is_populated = 0;
		gchar *sync_data = NULL;

		/* We need to hold on to the value of any previously set 'is_populated' flag */
		success = ebsql_exec_printf (
			ebsql, "SELECT is_populated FROM folders WHERE folder_id = %Q",
			get_int_cb, &is_populated, NULL, error, ebsql->priv->folderid);

		if (success) {
			/* We can't use e_book_sqlite_set_key_value_int() at this
			 * point as that would hold the access locks
			 */
			success = ebsql_exec_printf (
				ebsql, "INSERT or REPLACE INTO keys (key, value, folder_id) values (%Q, %Q, %Q)",
				NULL, NULL, NULL, error,
				E_BOOK_SQL_IS_POPULATED_KEY,
				is_populated ? "1" : "0",
				ebsql->priv->folderid);
		}

		/* Repeat for 'sync_data' */
		success = success && ebsql_exec_printf (
			ebsql, "SELECT sync_data FROM folders WHERE folder_id = %Q",
			get_string_cb, &sync_data, NULL, error, ebsql->priv->folderid);

		if (success) {
			success = ebsql_exec_printf (
				ebsql, "INSERT or REPLACE INTO keys (key, value, folder_id) values (%Q, %Q, %Q)",
				NULL, NULL, NULL, error,
				E_BOOK_SQL_SYNC_DATA_KEY,
				sync_data, ebsql->priv->folderid);

			g_free (sync_data);
		}
	}

	return success;
}

/* Called with the lock held and inside a transaction */
static gboolean
ebsql_init_locale (EBookSqlite *ebsql,
                   gint previous_schema,
                   gboolean already_exists,
                   GError **error)
{
	gchar *stored_lc_collate = NULL;
	gchar *stored_region_code = NULL;
	const gchar *lc_collate = NULL;
	gboolean success = TRUE;
	gboolean relocalize_needed = FALSE;

	/* Get the locale setting for this addressbook */
	if (already_exists) {
		success = ebsql_exec_printf (
			ebsql, "SELECT lc_collate FROM folders WHERE folder_id = %Q",
			get_string_cb, &stored_lc_collate, NULL, error, ebsql->priv->folderid);

		if (success)
			success = ebsql_exec_printf (
				ebsql, "SELECT countrycode FROM folders WHERE folder_id = %Q",
				get_string_cb, &stored_region_code, NULL, error, ebsql->priv->folderid);

		lc_collate = stored_lc_collate;
	}

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
		success = ebsql_set_locale_internal (ebsql, lc_collate, error);

	/* Check if we need to relocalize */
	if (success) {
		/* Need to relocalize the whole thing if the schema has been upgraded to version 7 */
		if (previous_schema >= 1 && previous_schema < 11)
			relocalize_needed = TRUE;

		/* We may need to relocalize for a country code change */
		else if (g_strcmp0 (ebsql->priv->region_code, stored_region_code) != 0)
			relocalize_needed = TRUE;
	}

	/* Reinsert all contacts with new locale & country code */
	if (success && relocalize_needed)
		success = ebsql_upgrade (ebsql, EBSQL_CHANGE_LAST, error);

	EBSQL_NOTE (
		SCHEMA,
		g_printerr (
			"SCHEMA: Initialized locale as '%s' (%s)\n",
			ebsql->priv->locale, success ? "success" : "failed"));

	g_free (stored_region_code);
	g_free (stored_lc_collate);

	return success;
}

static EBookSqlite *
ebsql_new_internal (const gchar *path,
		    ESource *source,
                    EbSqlVCardCallback vcard_callback,
                    EbSqlChangeCallback change_callback,
                    gpointer user_data,
                    GDestroyNotify user_data_destroy,
                    SummaryField *fields,
                    gint n_fields,
                    GCancellable *cancellable,
                    GError **error)
{
	EBookSqlite *ebsql;
	gchar *dirname = NULL;
	gint previous_schema = 0;
	gboolean already_exists = FALSE;
	gboolean success = TRUE;
	GSList *introspected_columns = NULL;

	g_return_val_if_fail (path != NULL, NULL);

	EBSQL_LOCK_MUTEX (&dbcon_lock);

	EBSQL_NOTE (
		SCHEMA,
		g_printerr ("SCHEMA: Creating new EBookSqlite at path '%s'\n", path));

	ebsql = ebsql_ref_from_hash (path);
	if (ebsql) {
		EBSQL_NOTE (SCHEMA, g_printerr ("SCHEMA: An EBookSqlite already existed\n"));
		goto exit;
	}

	ebsql = g_object_new (E_TYPE_BOOK_SQLITE, NULL);
	ebsql->priv->path = g_strdup (path);
	ebsql->priv->folderid = g_strdup (DEFAULT_FOLDER_ID);
	ebsql->priv->summary_fields = fields;
	ebsql->priv->n_summary_fields = n_fields;
	ebsql->priv->vcard_callback = vcard_callback;
	ebsql->priv->change_callback = change_callback;
	ebsql->priv->user_data = user_data;
	ebsql->priv->user_data_destroy = user_data_destroy;
	if (source != NULL)
		ebsql->priv->source = g_object_ref (source);
	else
		ebsql->priv->source = NULL;

	EBSQL_NOTE (REF_COUNTS, g_printerr ("EBookSqlite initially created\n"));

	/* Ensure existance of the directories leading up to 'path' */
	dirname = g_path_get_dirname (path);
	if (g_mkdir_with_parents (dirname, 0777) < 0) {
		EBSQL_SET_ERROR (
			error,
			E_BOOK_SQLITE_ERROR_LOAD,
			"Can not make parent directory: %s",
			g_strerror (errno));
		success = FALSE;
		goto exit;
	}

	/* The additional instance lock is unneccesarry because of the global
	 * lock held here, but let's keep it locked because we hold it while
	 * executing any SQLite code throughout this code
	 */
	EBSQL_LOCK_MUTEX (&ebsql->priv->lock);

	/* Initialize the SQLite (set some parameters and add some custom hooks) */
	if (!ebsql_init_sqlite (ebsql, path, error)) {
		EBSQL_UNLOCK_MUTEX (&ebsql->priv->lock);
		success = FALSE;
		goto exit;
	}

	/* Lets do it all atomically inside a single transaction */
	if (!ebsql_start_transaction (ebsql, EBSQL_LOCK_WRITE, cancellable, error)) {
		EBSQL_UNLOCK_MUTEX (&ebsql->priv->lock);
		success = FALSE;
		goto exit;
	}

	/* When loading addressbooks created by EBookBackendSqlite, we
	 * need to fetch the 'folderid' which was in use for that existing
	 * addressbook before introspecting it's summary and upgrading
	 * the schema.
	 */
	if (success)
		success = ebsql_resolve_folderid (
			ebsql,
			&previous_schema,
			&already_exists,
			error);

	/* Initialize main folders table, also retrieve the current
	 * schema version if the table already exists
	 */
	if (success)
		success = ebsql_init_folders (ebsql, previous_schema, error);

	/* Initialize the key/value table */
	if (success)
		success = ebsql_init_keys (ebsql, error);

	/* Determine if the addressbook already existed, and fill out
	 * some information in the main folder table
	 */
	if (success && !already_exists)
		success = ebsql_add_folder (ebsql, error);

	/* If the addressbook did exist, then check how it's configured.
	 *
	 * Let the existing summary information override the current
	 * one asked for by our callers.
	 *
	 * Some summary fields are also adjusted for schema upgrades
	 */
	if (success && already_exists)
		success = ebsql_introspect_summary (
			ebsql,
			previous_schema,
			&introspected_columns,
			error);

	/* Add the contacts table, ensure the right columns are defined
	 * to handle our summary configuration
	 */
	if (success)
		success = ebsql_init_contacts (
			ebsql,
			introspected_columns,
			error);

	/* Add any auxiliary tables which we might need to support our
	 * summary configuration.
	 *
	 * Any fields which represent a 'list-of-strings' require an
	 * auxiliary table to store them in.
	 */
	if (success)
		success = ebsql_init_aux_tables (ebsql, previous_schema, error);

	/* At this point we have resolved our schema, let's build our
	 * precompiled statements, we might use them to re-insert contacts
	 * in the next step
	 */
	if (success)
		success = ebsql_init_statements (ebsql, error);

	/* When porting from older schemas, we need to port the old 'is-populated' flag */
	if (success)
		success = ebsql_init_legacy_keys (ebsql, previous_schema, error);

	/* Load / resolve the current locale setting
	 *
	 * Also perform the overall upgrade in this step
	 * in the case that an upgrade happened, or a locale
	 * change is detected... all rows need to be renormalized
	 * for this.
	 */
	if (success)
		success = ebsql_init_locale (
			ebsql, previous_schema,
			already_exists, error);


	/* Schema 12 added E_CONTACT_PGP_CERT column into the summary;
	   the ebsql_init_locale() also calls ebsql_upgrade() for schema 10-,
	   thus call it here only for schema 11, to populate the PGP column */
	if (success && previous_schema == 11)
		success = ebsql_upgrade (ebsql, EBSQL_CHANGE_LAST, error);

	if (success)
		success = ebsql_commit_transaction (ebsql, error);
	else
		/* The GError is already set. */
		ebsql_rollback_transaction (ebsql, NULL);

	/* Release the instance lock and register to the global hash */
	EBSQL_UNLOCK_MUTEX (&ebsql->priv->lock);

	if (success)
		ebsql_register_to_hash (ebsql, path);

 exit:

	/* Cleanup and exit */
	EBSQL_UNLOCK_MUTEX (&dbcon_lock);

	/* If we failed somewhere, give up on creating the 'ebsql',
	 * otherwise add it to the hash table
	 */
	if (!success)
		g_clear_object (&ebsql);

	EBSQL_NOTE (
		SCHEMA,
		g_printerr (
			"SCHEMA: %s the new EBookSqlite\n",
			success ? "Successfully created" : "Failed to create"));

	g_slist_free_full (introspected_columns, (GDestroyNotify) g_free);
	g_free (dirname);

	return ebsql;
}

/**********************************************************
 *                   Inserting Contacts                   *
 **********************************************************/
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

typedef struct {
	gint country_code;
	gchar *national;
} E164Number;

static E164Number *
ebsql_e164_number_new (gint country_code,
                       gchar *national)
{
	E164Number *number = g_slice_new (E164Number);

	number->country_code = country_code;
	number->national = g_strdup (national);

	return number;
}

static void
ebsql_e164_number_free (E164Number *number)
{
	if (number) {
		g_free (number->national);
		g_slice_free (E164Number, number);
	}
}

static gint
ebsql_e164_number_find (E164Number *number_a,
                        E164Number *number_b)
{
	gint ret;

	ret = number_a->country_code - number_b->country_code;

	if (ret == 0)
		ret = g_strcmp0 (
			number_a->national,
			number_b->national);

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

			EBSQL_NOTE (
				CONVERT_E164,
				g_printerr (
					"Extracted e164 number from '%s' with "
					"country = %d national = %s\n",
					(gchar *) e_contact_get_const (contact, E_CONTACT_UID),
					this_country, this_national));

			number = ebsql_e164_number_new (
				this_country, this_national);
			extracted = g_list_prepend (extracted, number);
		}

		g_free (this_national);

		/* Clear the values, we'll insert new ones */
		e_vcard_attribute_param_remove_values (param);
		e_vcard_attribute_remove_param (attr, EVC_X_E164);
	}

	EBSQL_NOTE (
		CONVERT_E164,
		g_printerr (
			"Extracted %d numbers from '%s'\n",
			g_list_length (extracted),
			(gchar *) e_contact_get_const (contact, E_CONTACT_UID)));

	return extracted;
}

static gboolean
update_e164_attribute_params (EBookSqlite *ebsql,
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
			number.national = convert_phone (
				original_number,
				ebsql->priv->region_code,
				&(number.country_code));
		}

		if (number.national == NULL)
			continue;

		/* Count how many we successfully parsed in this region code */
		n_numbers++;

		/* Check if we have a differing e164 number, if there is no match
		 * in the old existing values then the vcard changed
		 */
		if (!g_list_find_custom (original_numbers, &number,
					 (GCompareFunc) ebsql_e164_number_find))
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

		EBSQL_NOTE (
			CONVERT_E164,
			g_printerr (
				"Converted '%s' to e164 number with country = %d "
				"national = %s for '%s' (changed %s)\n",
				original_number, number.country_code, number.national,
				(gchar *) e_contact_get_const (contact, E_CONTACT_UID),
				changed ? "yes" : "no"));

		g_free (number.national);
		g_free (country_string);
	}

	if (!changed &&
	    n_numbers != g_list_length (original_numbers))
		changed = TRUE;

	EBSQL_NOTE (
		CONVERT_E164,
		g_printerr (
			"Converted %d e164 numbers for '%s' which previously had %d e164 numbers\n",
			n_numbers,
			(gchar *) e_contact_get_const (contact, E_CONTACT_UID),
			g_list_length (original_numbers)));

	g_list_free_full (original_numbers, (GDestroyNotify) ebsql_e164_number_free);

	return changed;
}

static sqlite3_stmt *
ebsql_prepare_multi_delete (EBookSqlite *ebsql,
                            SummaryField *field,
                            GError **error)
{
	sqlite3_stmt *stmt = NULL;
	gchar *stmt_str;

	stmt_str = sqlite3_mprintf ("DELETE FROM %Q WHERE uid = :uid", field->aux_table);
	stmt = ebsql_prepare_statement (ebsql, stmt_str, error);
	sqlite3_free (stmt_str);

	return stmt;
}

static gboolean
ebsql_run_multi_delete (EBookSqlite *ebsql,
                        SummaryField *field,
                        const gchar *uid,
                        GError **error)
{
	sqlite3_stmt *stmt;
	gint ret;

	stmt = g_hash_table_lookup (ebsql->priv->multi_deletes, GUINT_TO_POINTER (field->field_id));

	/* This can return an error if a previous call to sqlite3_step() had errors,
	 * so let's just ignore any error in this case
	 */
	sqlite3_reset (stmt);

	/* Clear all previously set values */
	ret = sqlite3_clear_bindings (stmt);

	/* Set the UID host parameter statically */
	if (ret == SQLITE_OK)
		ret = sqlite3_bind_text (stmt, 1, uid, -1, SQLITE_STATIC);

	/* Run the statement */
	return ebsql_complete_statement (ebsql, stmt, ret, error);
}

static sqlite3_stmt *
ebsql_prepare_multi_insert (EBookSqlite *ebsql,
                            SummaryField *field,
                            GError **error)
{
	sqlite3_stmt *stmt = NULL;
	GString *string;

	string = g_string_sized_new (INSERT_MULTI_STMT_BYTES);
	ebsql_string_append_printf (string, "INSERT INTO %Q (uid, value", field->aux_table);

	if ((field->index & INDEX_FLAG (SUFFIX)) != 0)
		g_string_append (string, ", value_" EBSQL_SUFFIX_REVERSE);

	if ((field->index & INDEX_FLAG (PHONE)) != 0) {
		g_string_append (string, ", value_" EBSQL_SUFFIX_PHONE);
		g_string_append (string, ", value_" EBSQL_SUFFIX_COUNTRY);
	}

	g_string_append (string, ") VALUES (:uid, :value");

	if ((field->index & INDEX_FLAG (SUFFIX)) != 0)
		g_string_append (string, ", :value_" EBSQL_SUFFIX_REVERSE);

	if ((field->index & INDEX_FLAG (PHONE)) != 0) {
		g_string_append (string, ", :value_" EBSQL_SUFFIX_PHONE);
		g_string_append (string, ", :value_" EBSQL_SUFFIX_COUNTRY);
	}

	g_string_append_c (string, ')');

	stmt = ebsql_prepare_statement (ebsql, string->str, error);
	g_string_free (string, TRUE);

	return stmt;
}

static gboolean
ebsql_run_multi_insert_one (EBookSqlite *ebsql,
                            sqlite3_stmt *stmt,
                            SummaryField *field,
                            const gchar *uid,
                            const gchar *value,
                            GError **error)
{
	gchar *normal = e_util_utf8_normalize (value);
	gchar *str;
	gint ret, param_idx = 1;

	/* :uid */
	ret = sqlite3_bind_text (stmt, param_idx++, uid, -1, SQLITE_STATIC);

	if (ret == SQLITE_OK)  /* :value */
		ret = sqlite3_bind_text (stmt, param_idx++, normal, -1, g_free);

	if (ret == SQLITE_OK && (field->index & INDEX_FLAG (SUFFIX)) != 0) {
		if (normal)
			str = g_utf8_strreverse (normal, -1);
		else
			str = NULL;

		/* :value_reverse */
		ret = sqlite3_bind_text (stmt, param_idx++, str, -1, g_free);
	}

	if (ret == SQLITE_OK && (field->index & INDEX_FLAG (PHONE)) != 0) {
		gint country_code;

		str = convert_phone (
			normal, ebsql->priv->region_code,
			&country_code);
		str = remove_leading_zeros (str);

		/* :value_phone */
		ret = sqlite3_bind_text (stmt, param_idx++, str, -1, g_free);

		/* :value_country */
		if (ret == SQLITE_OK)
			sqlite3_bind_int (stmt, param_idx++, country_code);

	}

	/* Run the statement */
	return ebsql_complete_statement (ebsql, stmt, ret, error);
}

static gboolean
ebsql_run_multi_insert (EBookSqlite *ebsql,
                        SummaryField *field,
                        const gchar *uid,
                        EContact *contact,
                        GError **error)
{
	sqlite3_stmt *stmt;
	GList *values, *l;
	gboolean success = TRUE;

	stmt = g_hash_table_lookup (ebsql->priv->multi_inserts, GUINT_TO_POINTER (field->field_id));
	values = e_contact_get (contact, field->field_id);

	for (l = values; success && l != NULL; l = l->next) {
		gchar *value = (gchar *) l->data;

		success = ebsql_run_multi_insert_one (
			ebsql, stmt, field, uid, value, error);
	}

	/* Free the list of allocated strings */
	e_contact_attr_list_free (values);

	return success;
}

static sqlite3_stmt *
ebsql_prepare_insert (EBookSqlite *ebsql,
                      gboolean replace_existing,
                      GError **error)
{
	sqlite3_stmt *stmt;
	GString *string;
	gint i;

	string = g_string_new ("");
	if (replace_existing)
		ebsql_string_append_printf (
			string, "INSERT or REPLACE INTO %Q (",
			ebsql->priv->folderid);
	else
		ebsql_string_append_printf (
			string, "INSERT or FAIL INTO %Q (",
			ebsql->priv->folderid);

	/*
	 * First specify the column names for the insert, since it's possible we
	 * upgraded the DB and cannot be sure the order of the columns are ordered
	 * just how we like them to be.
	 */
	for (i = 0; i < ebsql->priv->n_summary_fields; i++) {
		SummaryField *field = &(ebsql->priv->summary_fields[i]);

		/* Multi values go into a separate table/statement */
		if (field->type != E_TYPE_CONTACT_ATTR_LIST) {

			/* Only add a ", " before every field except the first,
			 * this will not break because the first 2 fields (UID & REV)
			 * are string fields.
			 */
			if (i > 0)
				g_string_append (string, ", ");

			g_string_append (string, field->dbname);
		}

		if (field->type == G_TYPE_STRING) {

			if ((field->index & INDEX_FLAG (SORT_KEY)) != 0) {
				g_string_append (string, ", ");
				g_string_append (string, field->dbname);
				g_string_append (string, "_" EBSQL_SUFFIX_SORT_KEY);
			}

			if ((field->index & INDEX_FLAG (SUFFIX)) != 0) {
				g_string_append (string, ", ");
				g_string_append (string, field->dbname);
				g_string_append (string, "_" EBSQL_SUFFIX_REVERSE);
			}

			if ((field->index & INDEX_FLAG (PHONE)) != 0) {

				g_string_append (string, ", ");
				g_string_append (string, field->dbname);
				g_string_append (string, "_" EBSQL_SUFFIX_PHONE);

				g_string_append (string, ", ");
				g_string_append (string, field->dbname);
				g_string_append (string, "_" EBSQL_SUFFIX_COUNTRY);
			}
		}
	}
	g_string_append (string, ", vcard, bdata)");

	/*
	 * Now specify values for all of the column names we specified.
	 */
	g_string_append (string, " VALUES (");
	for (i = 0; i < ebsql->priv->n_summary_fields; i++) {
		SummaryField *field = &(ebsql->priv->summary_fields[i]);

		if (field->type != E_TYPE_CONTACT_ATTR_LIST) {
			/* Only add a ", " before every field except the first,
			 * this will not break because the first 2 fields (UID & REV)
			 * are string fields.
			 */
			if (i > 0)
				g_string_append (string, ", ");
		}

		if (field->type == G_TYPE_STRING || field->type == G_TYPE_BOOLEAN ||
		    field->type == E_TYPE_CONTACT_CERT) {

			g_string_append_c (string, ':');
			g_string_append (string, field->dbname);

			if ((field->index & INDEX_FLAG (SORT_KEY)) != 0)
				g_string_append_printf (string, ", :%s_" EBSQL_SUFFIX_SORT_KEY, field->dbname);

			if ((field->index & INDEX_FLAG (SUFFIX)) != 0)
				g_string_append_printf (string, ", :%s_" EBSQL_SUFFIX_REVERSE, field->dbname);

			if ((field->index & INDEX_FLAG (PHONE)) != 0) {
				g_string_append_printf (string, ", :%s_" EBSQL_SUFFIX_PHONE, field->dbname);
				g_string_append_printf (string, ", :%s_" EBSQL_SUFFIX_COUNTRY, field->dbname);
			}

		} else if (field->type != E_TYPE_CONTACT_ATTR_LIST)
			g_warn_if_reached ();
	}

	g_string_append (string, ", :vcard, :bdata)");

	stmt = ebsql_prepare_statement (ebsql, string->str, error);
	g_string_free (string, TRUE);

	return stmt;
}

static gboolean
ebsql_init_statements (EBookSqlite *ebsql,
                       GError **error)
{
	sqlite3_stmt *stmt;
	gint i;

	ebsql->priv->insert_stmt = ebsql_prepare_insert (ebsql, FALSE, error);
	if (!ebsql->priv->insert_stmt)
		goto preparation_failed;

	ebsql->priv->replace_stmt = ebsql_prepare_insert (ebsql, TRUE, error);
	if (!ebsql->priv->replace_stmt)
		goto preparation_failed;

	ebsql->priv->multi_deletes =
		g_hash_table_new_full (
			g_direct_hash, g_direct_equal,
			NULL,
			(GDestroyNotify) sqlite3_finalize);
	ebsql->priv->multi_inserts =
		g_hash_table_new_full (
			g_direct_hash, g_direct_equal,
			NULL,
			(GDestroyNotify) sqlite3_finalize);

	for (i = 0; i < ebsql->priv->n_summary_fields; i++) {
		SummaryField *field = &(ebsql->priv->summary_fields[i]);

		if (field->type != E_TYPE_CONTACT_ATTR_LIST)
			continue;

		stmt = ebsql_prepare_multi_insert (ebsql, field, error);
		if (!stmt)
			goto preparation_failed;

		g_hash_table_insert (
			ebsql->priv->multi_inserts,
			GUINT_TO_POINTER (field->field_id),
			stmt);

		stmt = ebsql_prepare_multi_delete (ebsql, field, error);
		if (!stmt)
			goto preparation_failed;

		g_hash_table_insert (
			ebsql->priv->multi_deletes,
			GUINT_TO_POINTER (field->field_id),
			stmt);
	}

	return TRUE;

 preparation_failed:

	return FALSE;
}

static gboolean
ebsql_run_insert (EBookSqlite *ebsql,
                  gboolean replace,
                  EContact *contact,
                  gchar *vcard,
                  const gchar *extra,
                  GError **error)
{
	EBookSqlitePrivate *priv;
	sqlite3_stmt *stmt;
	gint i, param_idx;
	gint ret;
	gboolean success;
	GError *local_error = NULL;

	priv = ebsql->priv;

	if (replace)
		stmt = ebsql->priv->replace_stmt;
	else
		stmt = ebsql->priv->insert_stmt;

	/* This can return an error if a previous call to sqlite3_step() had errors,
	 * so let's just ignore any error in this case
	 */
	sqlite3_reset (stmt);

	/* Clear all previously set values */
	ret = sqlite3_clear_bindings (stmt);

	for (i = 0, param_idx = 1; ret == SQLITE_OK && i < ebsql->priv->n_summary_fields; i++) {
		SummaryField *field = &(ebsql->priv->summary_fields[i]);

		if (field->type == G_TYPE_STRING) {
			gchar *val;
			gchar *normal;
			gchar *str;

			val = e_contact_get (contact, field->field_id);

			/* Special exception, never normalize/localize the UID or REV string */
			if (field->field_id != E_CONTACT_UID &&
			    field->field_id != E_CONTACT_REV) {
				normal = e_util_utf8_normalize (val);
			} else
				normal = g_strdup (val);

			/* Takes ownership of 'normal' */
			ret = sqlite3_bind_text (stmt, param_idx++, normal, -1, g_free);

			if (ret == SQLITE_OK &&
			    (field->index & INDEX_FLAG (SORT_KEY)) != 0) {
				if (val)
					str = e_collator_generate_key (ebsql->priv->collator, val, NULL);
				else
					str = g_strdup ("");

				ret = sqlite3_bind_text (stmt, param_idx++, str, -1, g_free);
			}

			if (ret == SQLITE_OK &&
			    (field->index & INDEX_FLAG (SUFFIX)) != 0) {
				if (normal)
					str = g_utf8_strreverse (normal, -1);
				else
					str = NULL;

				ret = sqlite3_bind_text (stmt, param_idx++, str, -1, g_free);
			}

			if (ret == SQLITE_OK &&
			    (field->index & INDEX_FLAG (PHONE)) != 0) {
				gint country_code;

				str = convert_phone (
					normal, ebsql->priv->region_code,
					&country_code);
				str = remove_leading_zeros (str);

				ret = sqlite3_bind_text (stmt, param_idx++, str, -1, g_free);
				if (ret == SQLITE_OK)
					sqlite3_bind_int (stmt, param_idx++, country_code);
			}

			g_free (val);
		} else if (field->type == G_TYPE_BOOLEAN) {
			gboolean val;

			val = e_contact_get (contact, field->field_id) ? TRUE : FALSE;

			ret = sqlite3_bind_int (stmt, param_idx++, val ? 1 : 0);
		} else if (field->type == E_TYPE_CONTACT_CERT) {
			EContactCert *cert = NULL;

			cert = e_contact_get (contact, field->field_id);

			/* We don't actually store the cert; only a boolean to indicate
			 * that is *has* a cert. */
			ret = sqlite3_bind_int (stmt, param_idx++, cert ? 1 : 0);
			e_contact_cert_free (cert);
		} else if (field->type != E_TYPE_CONTACT_ATTR_LIST)
			g_warn_if_reached ();
	}

	if (ret == SQLITE_OK) {

		EBSQL_NOTE (
			INSERT,
			g_printerr (
				"Inserting vcard for contact with UID '%s'\n%s\n",
				(gchar *) e_contact_get_const (contact, E_CONTACT_UID),
				vcard ? vcard : "(no vcard)"));

		/* If we have a priv->vcard_callback, then it's a shallow addressbook
		 * and we don't populate the vcard column, need to free it anyway
		 */
		if (priv->vcard_callback != NULL) {
			g_free (vcard);
			vcard = NULL;
		}

		ret = sqlite3_bind_text (stmt, param_idx++, vcard, -1, g_free);
	}

	/* The extra data */
	if (ret == SQLITE_OK)
		ret = sqlite3_bind_text (stmt, param_idx++, g_strdup (extra), -1, g_free);

	/* Run the statement */
	success = ebsql_complete_statement (ebsql, stmt, ret, &local_error);

	EBSQL_NOTE (
		INSERT,
		g_printerr (
			"%s contact with UID '%s' and extra data '%s' vcard: %s (error: %s)\n",
			success ? "Succesfully inserted" : "Failed to insert",
			(gchar *) e_contact_get_const (contact, E_CONTACT_UID), extra,
			vcard ? "yes" : "no",
			local_error ? local_error->message : "(none)"));

	if (!success)
		g_propagate_error (error, local_error);

	return success;
}

static gboolean
ebsql_insert_contact (EBookSqlite *ebsql,
                      EbSqlChangeType change_type,
                      EContact *contact,
                      const gchar *original_vcard,
                      const gchar *extra,
                      gboolean replace,
                      GError **error)
{
	EBookSqlitePrivate *priv;
	gboolean e164_changed = FALSE;
	gboolean success;
	gchar *uid, *vcard = NULL;

	priv = ebsql->priv;
	uid = e_contact_get (contact, E_CONTACT_UID);

	/* Update E.164 parameters in vcard if needed */
	e164_changed = update_e164_attribute_params (
		ebsql, contact, priv->region_code);

	if (e164_changed || original_vcard == NULL) {

		/* Generate a new one if it changed (or if we don't have one) */
		vcard = e_vcard_to_string (E_VCARD (contact), EVC_FORMAT_VCARD_30);

		if (e164_changed &&
		    change_type != EBSQL_CHANGE_LAST &&
		    ebsql->priv->change_callback)
			ebsql->priv->change_callback (change_type,
						      uid, extra, vcard,
						      ebsql->priv->user_data);
	} else {

		vcard = g_strdup (original_vcard);
	}

	/* This actually consumes 'vcard' */
	success = ebsql_run_insert (ebsql, replace, contact, vcard, extra, error);

	/* Update attribute list table */
	if (success) {
		gint i;

		for (i = 0; success && i < priv->n_summary_fields; i++) {
			SummaryField *field = &(ebsql->priv->summary_fields[i]);

			if (field->type != E_TYPE_CONTACT_ATTR_LIST)
				continue;

			success = ebsql_run_multi_delete (
				ebsql, field, uid, error);

			if (success)
				success = ebsql_run_multi_insert (
					ebsql, field, uid, contact, error);
		}
	}

	g_free (uid);

	return success;
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

#define EBSQL_STATUS_STR(status) \
	((status) == PREFLIGHT_OK ? "Ok" : \
	 (status) == PREFLIGHT_LIST_ALL ? "List all" : \
	 (status) == PREFLIGHT_NOT_SUMMARIZED ? "Not Summarized" : \
	 (status) == PREFLIGHT_INVALID ? "Invalid" : \
	 (status) == PREFLIGHT_UNSUPPORTED ? "Unsupported" : "(unknown status)")

/* Whether we can satisfy the constraints or whether we
 * need to do a fallback, we still need to call
 * ebsql_generate_constraints()
 */
#define EBSQL_STATUS_GEN_CONSTRAINTS(status) \
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

#define EBSQL_QUERY_TYPE_STR(query) \
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

#define EBSQL_FIELD_ID_STR(field_id) \
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
#if 0
	g_ptr_array_insert (array, idx, data);
#else
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
#endif
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
                        guint sub_type, gboolean inc_cond_count)
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
	gint sub_counter = 1, i;

	g_return_if_fail (offset >= 0 && offset < n_elements);
	g_return_if_fail (elements[offset]->query >= BOOK_QUERY_SUB_FIRST);
	g_return_if_fail (callback != NULL);

	if (include_delim && !callback (elements[offset], 0, offset, user_data))
		return;

	for (i = (offset + 1); sub_counter > 0 && i < n_elements; i++) {

		if (elements[i]->query >= BOOK_QUERY_SUB_FIRST) {

			if (elements[i]->query == BOOK_QUERY_SUB_END)
				sub_counter--;
			else
				sub_counter++;

			if (include_delim &&
			    !callback (elements[i], sub_counter, i, user_data))
				break;
		} else {

			if (!callback (elements[i], sub_counter, i, user_data))
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
	gint i, j, len;
	guint query_type;

	query_type = GPOINTER_TO_UINT (data);

	/* The compound query delimiter is the first element in this return array */
	result_array = g_ptr_array_new_with_free_func ((GDestroyNotify) query_element_free);
	element = query_delimiter_new (query_type);
	g_ptr_array_add (result_array, element);

	EBSQL_NOTE (
		PREFLIGHT,
		g_printerr (
			"PREFLIGHT INIT: Open sub: %s\n",
			EBSQL_QUERY_TYPE_STR (query_type)));

	for (i = 0; i < argc; i++) {
		sub_result = e_sexp_term_eval (f, argv[i]);

		if (sub_result->type == ESEXP_RES_ARRAY_PTR) {
			/* Steal the elements directly from the sub result */
			sub_elements = (QueryElement **) sub_result->value.ptrarray->pdata;
			len = sub_result->value.ptrarray->len;

			for (j = 0; j < len; j++) {
				element = sub_elements[j];
				sub_elements[j] = NULL;

				g_ptr_array_add (result_array, element);
			}
		}
		e_sexp_result_free (f, sub_result);
	}

	EBSQL_NOTE (
		PREFLIGHT,
		g_printerr (
			"PREFLIGHT INIT: Close sub: %s\n",
			EBSQL_QUERY_TYPE_STR (query_type)));

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

	EBSQL_NOTE (
		PREFLIGHT,
		g_printerr (
			"PREFLIGHT INIT: Adding field test: `%s' on field `%s' "
			"(field name: %s query value: %s query extra: %s)\n",
			EBSQL_QUERY_TYPE_STR (query_type),
			EBSQL_FIELD_ID_STR (field_id),
			query_name, query_value, query_extra));

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
	gint esexp_error, i;

	if (sexp == NULL || *sexp == '\0') {
		context->status = PREFLIGHT_LIST_ALL;
		return;
	}

	sexp_parser = e_sexp_new ();

	for (i = 0; i < G_N_ELEMENTS (check_symbols); i++) {
		if (check_symbols[i].subset) {
			e_sexp_add_ifunction (
				sexp_parser, 0, check_symbols[i].name,
				func_check_subset,
				GUINT_TO_POINTER (check_symbols[i].test));
		} else {
			e_sexp_add_function (
				sexp_parser, 0, check_symbols[i].name,
				func_check,
				GUINT_TO_POINTER (check_symbols[i].test));
		}
	}

	e_sexp_input_text (sexp_parser, sexp, strlen (sexp));
	esexp_error = e_sexp_parse (sexp_parser);

	if (esexp_error == -1) {
		context->status = PREFLIGHT_INVALID;

		EBSQL_NOTE (
			PREFLIGHT,
			g_printerr ("PREFLIGHT INIT: Sexp parse error\n"));
	} else {

		result = e_sexp_eval (sexp_parser);
		if (result) {

			if (result->type == ESEXP_RES_ARRAY_PTR) {

				/* Just steal the array away from the ESexpResult */
				context->constraints = result->value.ptrarray;
				result->value.ptrarray = NULL;

			} else {
				context->status = PREFLIGHT_INVALID;

				EBSQL_NOTE (
					PREFLIGHT,
					g_printerr ("PREFLIGHT INIT: ERROR, Did not get GPtrArray\n"));
			}
		}

		e_sexp_result_free (sexp_parser, result);
	}

	g_object_unref (sexp_parser);

	EBSQL_NOTE (
		PREFLIGHT,
		g_printerr (
			"PREFLIGHT INIT: Completed with status %s\n",
			EBSQL_STATUS_STR (context->status)));
}

typedef struct {
	EBookSqlite   *ebsql;
	SummaryField  *field;
	gboolean       condition;
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
		test->field = summary_field_get (data->ebsql, test->field_id);

	if (test->field && test->field->type == E_TYPE_CONTACT_ATTR_LIST)
		data->condition = TRUE;

	/* Keep looping until we find one */
	return (data->condition == FALSE);
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
		test->field = summary_field_get (data->ebsql, test->field_id);

	if (test->field && data->field && test->field != data->field)
		data->condition = TRUE;
	else
		data->field = test->field;

	/* Keep looping until we find one */
	return (data->condition == FALSE);
}

/* What is done in this pass:
 *  o Viability of the query is analyzed, i.e. can it be done with the summary columns.
 *  o Phone numbers are parsed and loaded onto QueryPhoneTests
 *  o Bitmask of auxiliary tables is collected
 */
static void
query_preflight_check (PreflightContext *context,
                       EBookSqlite *ebsql)
{
	gint i, n_elements;
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

	for (i = 0; i < n_elements; i++) {
		QueryFieldTest *test;
		guint           field_test;

		EBSQL_NOTE (
			PREFLIGHT,
			g_printerr (
				"PREFLIGHT CHECK: Encountered: %s\n",
				EBSQL_QUERY_TYPE_STR (elements[i]->query)));

		if (elements[i]->query >= BOOK_QUERY_SUB_FIRST) {
			AttrListCheckData data = { ebsql, NULL, FALSE };

			switch (elements[i]->query) {
			case BOOK_QUERY_SUB_OR:
				/* An OR doesn't have to force us to use a LEFT JOIN, as long
				   as all its sub-conditions are on the same field. */
				query_preflight_foreach_sub (elements,
							     n_elements,
							     i, FALSE,
							     check_different_fields_cb,
							     &data);
				/* falls through */
			case BOOK_QUERY_SUB_AND:
				sub_query_context_push (ctx, elements[i]->query, data.condition);
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
							     i, FALSE,
							     check_has_attr_list_cb,
							     &data);

				if (data.condition) {
					context->status = MAX (
						context->status,
						PREFLIGHT_NOT_SUMMARIZED);
					EBSQL_NOTE (
						PREFLIGHT,
						g_printerr (
							"PREFLIGHT CHECK: "
							"Setting invalid for NOT (mutli-attribute), "
							"new status: %s\n",
							EBSQL_STATUS_STR (context->status)));
				}
				break;

			default:
				g_warn_if_reached ();
			}

			continue;
		}

		test = (QueryFieldTest *) elements[i];
		field_test = (EBookQueryTest) test->query;

		if (!test->field)
			test->field = summary_field_get (ebsql, test->field_id);

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
					EBSQL_NOTE (
						PREFLIGHT,
						g_printerr (
							"PREFLIGHT CHECK: "
							"Encountered lonesome 'x-evolution-any-field' with empty value, "
							"new status: %s\n",
							EBSQL_STATUS_STR (context->status)));
				} else {

					/* Searching for a value with 'x-evolution-any-field' is
					 * not a summary query.
					 */
					context->status = MAX (context->status, PREFLIGHT_NOT_SUMMARIZED);
					EBSQL_NOTE (
						PREFLIGHT,
						g_printerr (
							"PREFLIGHT CHECK: "
							"Encountered 'x-evolution-any-field', "
							"new status: %s\n",
							EBSQL_STATUS_STR (context->status)));
				}

			} else {

				/* Couldnt resolve the field, it's not a summary query */
				context->status = MAX (context->status, PREFLIGHT_NOT_SUMMARIZED);
				EBSQL_NOTE (
					PREFLIGHT,
					g_printerr (
						"PREFLIGHT CHECK: "
						"Field `%s' not in the summary, new status: %s\n",
						EBSQL_FIELD_ID_STR (test->field_id),
						EBSQL_STATUS_STR (context->status)));
			}
		}

		if (test->field && test->field->type == E_TYPE_CONTACT_CERT) {
			/* For certificates, and later potentially other fields,
			 * the only information in the summary is the fact that
			 * they exist, or not. So the only check we can do from
			 * the summary is BOOK_QUERY_EXISTS. */
			if (field_test != BOOK_QUERY_EXISTS) {
				context->status = MAX (context->status, PREFLIGHT_NOT_SUMMARIZED);
				EBSQL_NOTE (
					PREFLIGHT,
					g_printerr (
						"PREFLIGHT CHECK: "
						"Cannot perform '%s' check on existence summary field '%s', new status: %s\n",
						EBSQL_QUERY_TYPE_STR (field_test),
						EBSQL_FIELD_ID_STR (test->field_id),
						EBSQL_STATUS_STR (context->status)));
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
					EBSQL_NOTE (
						PREFLIGHT,
						g_printerr (
							"PREFLIGHT CHECK: "
							"Refusing pattern match on boolean field `%s', new status: %s\n",
							EBSQL_FIELD_ID_STR (test->field_id),
							EBSQL_STATUS_STR (context->status)));
				}
			}

			break;

		case BOOK_QUERY_EXISTS_VCARD:
			/* Exists vCard queries only supported in the fallback */
			context->status = MAX (context->status, PREFLIGHT_NOT_SUMMARIZED);
			EBSQL_NOTE (
				PREFLIGHT,
				g_printerr (
					"PREFLIGHT CHECK: "
					"Exists vCard requires full data, new status: %s\n",
					EBSQL_STATUS_STR (context->status)));
			break;

		case E_BOOK_QUERY_REGEX_RAW:
			/* Raw regex queries only supported in the fallback */
			context->status = MAX (context->status, PREFLIGHT_NOT_SUMMARIZED);
			EBSQL_NOTE (
				PREFLIGHT,
				g_printerr (
					"PREFLIGHT CHECK: "
					"Raw regexp requires full data, new status: %s\n",
					EBSQL_STATUS_STR (context->status)));
			break;

		case E_BOOK_QUERY_EQUALS_PHONE_NUMBER:
		case E_BOOK_QUERY_EQUALS_NATIONAL_PHONE_NUMBER:
		case E_BOOK_QUERY_EQUALS_SHORT_PHONE_NUMBER:

			/* Phone number queries are supported so long as they are in the summary,
			 * libphonenumber is available, and the phone number string is a valid one
			 */
			if (!e_phone_number_is_supported ()) {

				context->status = MAX (context->status, PREFLIGHT_UNSUPPORTED);
				EBSQL_NOTE (
					PREFLIGHT,
					g_printerr (
						"PREFLIGHT CHECK: "
						"Usupported phone number query, new status: %s\n",
						EBSQL_STATUS_STR (context->status)));
			} else {
				QueryPhoneTest *phone_test = (QueryPhoneTest *) test;
				EPhoneNumberCountrySource source;
				EPhoneNumber *number;
				const gchar *region_code;

				if (phone_test->region)
					region_code = phone_test->region;
				else
					region_code = ebsql->priv->region_code;

				number = e_phone_number_from_string (
					phone_test->value,
					region_code, NULL);

				if (number == NULL) {

					context->status = MAX (context->status, PREFLIGHT_INVALID);
					EBSQL_NOTE (
						PREFLIGHT,
						g_printerr (
							"PREFLIGHT CHECK: "
							"Invalid phone number `%s', new status: %s\n",
							phone_test->value,
							EBSQL_STATUS_STR (context->status)));
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
			gint aux_index = summary_field_get_index (ebsql, test->field_id);

			/* It's really improbable that we ever get 64 fields in the summary
			 * In any case we warn about this in e_book_sqlite_new_full().
			 */
			g_warn_if_fail (aux_index >= 0 && aux_index < EBSQL_MAX_SUMMARY_FIELDS);

			/* Just to mute a compiler warning when aux_index == -1 */
			aux_index = ABS (aux_index);

			context->aux_mask |= (1 << aux_index);
			EBSQL_NOTE (
				PREFLIGHT,
				g_printerr (
					"PREFLIGHT CHECK: "
					"Adding auxiliary field `%s' to the mask\n",
					EBSQL_FIELD_ID_STR (test->field_id)));

			/* If this condition is a *requirement* for the overall query to
			   match a given record (i.e. there's no surrounding 'OR' but
			   only 'AND'), then we can use an inner join for the query and
			   it will be a lot more efficient. If records without this
			   condition can also match the overall condition, then we must
			   use LEFT JOIN. */
			if (sub_query_context_peek_cond_counter (ctx)) {
				context->left_join_mask |= (1 << aux_index);
				EBSQL_NOTE (
					PREFLIGHT,
					g_printerr (
						"PREFLIGHT CHECK: "
						"Using LEFT JOIN because auxiliary field is not absolute requirement\n"));
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
                                      EBookSqlite *ebsql)
{
	gint i, j;

	for (i = 0; context->constraints != NULL && i < context->constraints->len; i++) {
		SummaryField *family_name, *given_name, *nickname;
		QueryElement *element;
		QueryFieldTest *test;

		element = g_ptr_array_index (context->constraints, i);

		if (element->query >= BOOK_QUERY_SUB_FIRST)
			continue;

		test = (QueryFieldTest *) element;
		if (test->field_id != E_CONTACT_FULL_NAME)
			continue;

		family_name = summary_field_get (ebsql, E_CONTACT_FAMILY_NAME);
		given_name = summary_field_get (ebsql, E_CONTACT_GIVEN_NAME);
		nickname = summary_field_get (ebsql, E_CONTACT_NICKNAME);

		/* If any of these are in the summary, then we'll construct
		 * a grouped OR statment for this E_CONTACT_FULL_NAME test */
		if (family_name || given_name || nickname) {
			/* Add the OR directly before the E_CONTACT_FULL_NAME test */
			constraints_insert_delimiter (context->constraints, i, BOOK_QUERY_SUB_OR);

			j = i + 2;

			if (family_name)
				constraints_insert_field_test (
					context->constraints, j++,
					family_name, test->query,
					test->value);

			if (given_name)
				constraints_insert_field_test (
					context->constraints, j++,
					given_name, test->query,
					test->value);

			if (nickname)
				constraints_insert_field_test (
					context->constraints, j++,
					nickname, test->query,
					test->value);

			constraints_insert_delimiter (context->constraints, j, BOOK_QUERY_SUB_END);

			i = j;
		}
	}
}

static void
query_preflight (PreflightContext *context,
                 EBookSqlite *ebsql,
                 const gchar *sexp)
{
	EBSQL_NOTE (PREFLIGHT, g_printerr ("PREFLIGHT BEGIN\n"));
	query_preflight_initialize (context, sexp);

	if (context->status == PREFLIGHT_OK) {

		query_preflight_check (context, ebsql);

		/* No need to change the constraints if we're not
		 * going to generate statements with it
		 */
		if (context->status == PREFLIGHT_OK) {
			EBSQL_NOTE (
				PREFLIGHT,
				g_printerr ("PREFLIGHT: Substituting full name\n"));

			/* Handle E_CONTACT_FULL_NAME substitutions */
			query_preflight_substitute_full_name (context, ebsql);

		} else {
			EBSQL_NOTE (PREFLIGHT, g_printerr ("PREFLIGHT: Clearing context\n"));

			/* We might use this context to perform a fallback query,
			 * so let's clear out all the constraints now
			 */
			preflight_context_clear (context);
		}
	}

	EBSQL_NOTE (
		PREFLIGHT,
		g_printerr (
			"PREFLIGHT END (status: %s)\n",
			EBSQL_STATUS_STR (context->status)));
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

typedef void (* GenerateFieldTest) (EBookSqlite      *ebsql,
				    GString          *string,
				    QueryFieldTest   *test);

/* This function escapes characters which need escaping
 * for LIKE statements as well as the single quotes.
 *
 * The return value is not suitable to be formatted
 * with %Q or %q
 */
static gchar *
ebsql_normalize_for_like (QueryFieldTest *test,
                          gboolean reverse_string,
                          gboolean *escape_needed)
{
	GString *str;
	size_t len;
	gchar c;
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
	str = g_string_sized_new (2 * len + 4 + strlen (EBSQL_ESCAPE_SEQUENCE) - 1);

	ptr = str_to_escape;
	while ((c = *ptr++)) {
		if (c == '\'') {
			g_string_append_c (str, '\'');
		} else if (c == '%' || c == '_' || c == '^') {
			g_string_append_c (str, '^');
			escape_modifier_needed = TRUE;
		}

		g_string_append_c (str, c);
	}

	if (escape_needed)
		*escape_needed = escape_modifier_needed;

	g_free (freeme);
	g_free (reverse);

	return g_string_free (str, FALSE);
}

static void
field_test_query_is (EBookSqlite *ebsql,
                     GString *string,
                     QueryFieldTest *test)
{
	SummaryField *field = test->field;
	gchar *normal;

	ebsql_string_append_column (string, field, NULL);

	if (test->field_id == E_CONTACT_UID ||
	    test->field_id == E_CONTACT_REV) {
		/* UID & REV fields are not normalized in the summary */
		ebsql_string_append_printf (string, " = %Q", test->value);
	} else {
		normal = e_util_utf8_normalize (test->value);
		ebsql_string_append_printf (string, " = %Q", normal);
		g_free (normal);
	}
}

static void
field_test_query_contains (EBookSqlite *ebsql,
                           GString *string,
                           QueryFieldTest *test)
{
	SummaryField *field = test->field;
	gboolean need_escape;
	gchar *escaped;

	escaped = ebsql_normalize_for_like (test, FALSE, &need_escape);

	g_string_append_c (string, '(');

	ebsql_string_append_column (string, field, NULL);
	g_string_append (string, " IS NOT NULL AND ");
	ebsql_string_append_column (string, field, NULL);
	g_string_append (string, " LIKE '%");
	g_string_append (string, escaped);
	g_string_append (string, "%'");

	if (need_escape)
		g_string_append (string, EBSQL_ESCAPE_SEQUENCE);

	g_string_append_c (string, ')');

	g_free (escaped);
}

static void
field_test_query_begins_with (EBookSqlite *ebsql,
                              GString *string,
                              QueryFieldTest *test)
{
	SummaryField *field = test->field;
	gboolean need_escape;
	gchar *escaped;

	escaped = ebsql_normalize_for_like (test, FALSE, &need_escape);

	g_string_append_c (string, '(');
	ebsql_string_append_column (string, field, NULL);
	g_string_append (string, " IS NOT NULL AND ");

	ebsql_string_append_column (string, field, NULL);
	g_string_append (string, " LIKE \'");
	g_string_append (string, escaped);
	g_string_append (string, "%\'");

	if (need_escape)
		g_string_append (string, EBSQL_ESCAPE_SEQUENCE);
	g_string_append_c (string, ')');

	g_free (escaped);
}

static void
field_test_query_ends_with (EBookSqlite *ebsql,
                            GString *string,
                            QueryFieldTest *test)
{
	SummaryField *field = test->field;
	gboolean need_escape;
	gchar *escaped;

	if ((field->index & INDEX_FLAG (SUFFIX)) != 0) {

		escaped = ebsql_normalize_for_like (test, TRUE, &need_escape);

		g_string_append_c (string, '(');
		ebsql_string_append_column (string, field, EBSQL_SUFFIX_REVERSE);
		g_string_append (string, " IS NOT NULL AND ");

		ebsql_string_append_column (string, field, EBSQL_SUFFIX_REVERSE);
		g_string_append (string, " LIKE \'");
		g_string_append (string, escaped);
		g_string_append (string, "%\'");

	} else {

		escaped = ebsql_normalize_for_like (test, FALSE, &need_escape);
		g_string_append_c (string, '(');

		ebsql_string_append_column (string, field, NULL);
		g_string_append (string, " IS NOT NULL AND ");

		ebsql_string_append_column (string, field, NULL);
		g_string_append (string, " LIKE \'%");
		g_string_append (string, escaped);
		g_string_append (string, "\'");
	}

	if (need_escape)
		g_string_append (string, EBSQL_ESCAPE_SEQUENCE);

	g_string_append_c (string, ')');
	g_free (escaped);
}

static void
field_test_query_eqphone (EBookSqlite *ebsql,
                          GString *string,
                          QueryFieldTest *test)
{
	SummaryField *field = test->field;
	QueryPhoneTest *phone_test = (QueryPhoneTest *) test;

	if ((field->index & INDEX_FLAG (PHONE)) != 0) {

		g_string_append_c (string, '(');
		ebsql_string_append_column (string, field, EBSQL_SUFFIX_PHONE);
		ebsql_string_append_printf (string, " = %Q AND ", phone_test->national);

		/* For exact matches, a country code qualifier is required by both
		 * query input and row input
		 */
		ebsql_string_append_column (string, field, EBSQL_SUFFIX_COUNTRY);
		g_string_append (string, " != 0 AND ");

		ebsql_string_append_column (string, field, EBSQL_SUFFIX_COUNTRY);
		ebsql_string_append_printf (string, " = %d", phone_test->country);
		g_string_append_c (string, ')');

	} else {

		/* No indexed columns available, perform the fallback */
		g_string_append (string, EBSQL_FUNC_EQPHONE_EXACT " (");
		ebsql_string_append_column (string, field, NULL);
		ebsql_string_append_printf (string, ", %Q)", test->value);
	}
}

static void
field_test_query_eqphone_national (EBookSqlite *ebsql,
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
		ebsql_string_append_column (string, field, EBSQL_SUFFIX_PHONE);
		ebsql_string_append_printf (string, " = %Q", phone_test->national);

		/* When doing a national search, no need to check country
		 * code unless the query number also has a country code
		 */
		if (phone_test->country) {
			/* Generate: (phone = %Q AND (country = 0 OR country = %d)) */
			g_string_append (string, " AND (");
			ebsql_string_append_column (string, field, EBSQL_SUFFIX_COUNTRY);
			g_string_append (string, " = 0 OR ");
			ebsql_string_append_column (string, field, EBSQL_SUFFIX_COUNTRY);
			ebsql_string_append_printf (string, " = %d))", phone_test->country);

		}

	} else {

		/* No indexed columns available, perform the fallback */
		g_string_append (string, EBSQL_FUNC_EQPHONE_NATIONAL " (");
		ebsql_string_append_column (string, field, NULL);
		ebsql_string_append_printf (string, ", %Q)", test->value);
	}
}

static void
field_test_query_eqphone_short (EBookSqlite *ebsql,
                                GString *string,
                                QueryFieldTest *test)
{
	SummaryField *field = test->field;

	/* No quick way to do the short match */
	g_string_append (string, EBSQL_FUNC_EQPHONE_SHORT " (");
	ebsql_string_append_column (string, field, NULL);
	ebsql_string_append_printf (string, ", %Q)", test->value);
}

static void
field_test_query_regex_normal (EBookSqlite *ebsql,
                               GString *string,
                               QueryFieldTest *test)
{
	SummaryField *field = test->field;
	gchar *normal;

	normal = e_util_utf8_normalize (test->value);

	if (field->aux_table)
		ebsql_string_append_printf (
			string, "%s.value REGEXP %Q",
			field->aux_table_symbolic,
			normal);
	else
		ebsql_string_append_printf (
			string, "summary.%s REGEXP %Q",
			field->dbname,
			normal);

	g_free (normal);
}

static void
field_test_query_exists (EBookSqlite *ebsql,
                         GString *string,
                         QueryFieldTest *test)
{
	SummaryField *field = test->field;

	ebsql_string_append_column (string, field, NULL);

	if (test->field->type == E_TYPE_CONTACT_CERT)
		ebsql_string_append_printf (string, " IS NOT '0'");
	else
		ebsql_string_append_printf (string, " IS NOT NULL");
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
	SEARCH_FULL,          /* Get a list of EbSqlSearchData */
	SEARCH_UID_AND_REV,   /* Get a list of EbSqlSearchData, with shallow vcards only containing UID & REV */
	SEARCH_UID,           /* Get a list of UID strings */
	SEARCH_COUNT,         /* Get the number of matching rows */
} SearchType;

static void
ebsql_generate_constraints (EBookSqlite *ebsql,
                            GString *string,
                            GPtrArray *constraints,
                            const gchar *sexp)
{
	SubQueryContext *ctx;
	QueryDelimiter *delim;
	QueryFieldTest *test;
	QueryElement **elements;
	gint n_elements, i;

	/* If there are no constraints, we generate the fallback constraint for 'sexp' */
	if (constraints == NULL) {
		ebsql_string_append_printf (
			string,
			EBSQL_FUNC_COMPARE_VCARD " (%Q, %s)",
			sexp, EBSQL_VCARD_FRAGMENT (ebsql));
		return;
	}

	elements = (QueryElement **) constraints->pdata;
	n_elements = constraints->len;

	ctx = sub_query_context_new ();

	for (i = 0; i < n_elements; i++) {
		GenerateFieldTest generate_test_func = NULL;

		/* Seperate field tests with the appropriate grouping */
		if (elements[i]->query != BOOK_QUERY_SUB_END &&
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

		if (elements[i]->query >= BOOK_QUERY_SUB_FIRST) {
			delim = (QueryDelimiter *) elements[i];

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
		test = (QueryFieldTest *) elements[i];
		if (test->query < G_N_ELEMENTS (field_test_func_table))
			generate_test_func = field_test_func_table[test->query];

		/* These should never happen, if it does it should be
		 * fixed in the preflight checks
		 */
		g_warn_if_fail (generate_test_func != NULL);
		g_warn_if_fail (test->field != NULL);

		/* Generate the field test */
		/* coverity[var_deref_op] */
		generate_test_func (ebsql, string, test);
	}

	sub_query_context_free (ctx);
}

/* Generates the SELECT portion of the query, this will take care of
 * preparing the context of the query, and add the needed JOIN statements
 * based on which fields are referenced in the query expression.
 *
 * This also handles getting the correct callback and asking for the
 * right data depending on the 'search_type'
 */
static EbSqlRowFunc
ebsql_generate_select (EBookSqlite *ebsql,
                       GString *string,
                       SearchType search_type,
                       PreflightContext *context,
                       GError **error)
{
	EbSqlRowFunc callback = NULL;
	gboolean add_auxiliary_tables = FALSE;
	gint i;

	if (context->status == PREFLIGHT_OK &&
	    context->aux_mask != 0)
		add_auxiliary_tables = TRUE;

	g_string_append (string, "SELECT ");
	if (add_auxiliary_tables)
		g_string_append (string, "DISTINCT ");

	switch (search_type) {
	case SEARCH_FULL:
		callback = collect_full_results_cb;
		g_string_append (string, "summary.uid, ");
		g_string_append (string, EBSQL_VCARD_FRAGMENT (ebsql));
		g_string_append (string, ", summary.bdata ");
		break;
	case SEARCH_UID_AND_REV:
		callback = collect_lean_results_cb;
		g_string_append (string, "summary.uid, summary.Rev, summary.bdata ");
		break;
	case SEARCH_UID:
		callback = collect_uid_results_cb;
		g_string_append (string, "summary.uid ");
		break;
	case SEARCH_COUNT:
		callback = get_count_cb;
		if (context->aux_mask != 0)
			g_string_append (string, "count (DISTINCT summary.uid) ");
		else
			g_string_append (string, "count (*) ");
		break;
	}

	ebsql_string_append_printf (string, "FROM %Q AS summary", ebsql->priv->folderid);

	/* Add any required auxiliary tables into the query context */
	if (add_auxiliary_tables) {
		for (i = 0; i < ebsql->priv->n_summary_fields; i++) {

			/* We cap this at EBSQL_MAX_SUMMARY_FIELDS (64 bits) at creation time */
			if ((context->aux_mask & (1 << i)) != 0) {
				SummaryField *field = &(ebsql->priv->summary_fields[i]);
				gboolean left_join = (context->left_join_mask >> i) & 1;

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
				ebsql_string_append_printf (
					string, " %sJOIN %Q AS %s ON %s%s.uid = summary.uid",
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
ebsql_is_autocomplete_query (PreflightContext *context)
{
	QueryFieldTest *test;
	QueryElement **elements;
	gint n_elements, i;
	int non_aux_fields = 0;

	if (context->status != PREFLIGHT_OK || context->aux_mask == 0)
		return FALSE;

	elements = (QueryElement **) context->constraints->pdata;
	n_elements = context->constraints->len;

	for (i = 0; i < n_elements; i++) {
		test = (QueryFieldTest *) elements[i];

		/* For these, check if the field being operated on is
		   an auxiliary field or not. */
		if (elements[i]->query == E_BOOK_QUERY_BEGINS_WITH ||
		    elements[i]->query == E_BOOK_QUERY_ENDS_WITH ||
		    elements[i]->query == E_BOOK_QUERY_IS ||
		    elements[i]->query == BOOK_QUERY_EXISTS ||
		    elements[i]->query == E_BOOK_QUERY_CONTAINS) {
			if (test->field->type != E_TYPE_CONTACT_ATTR_LIST)
				non_aux_fields++;
			continue;
		}

		/* Nothing else is allowed other than "(or" ... ")" */
		if (elements[i]->query != BOOK_QUERY_SUB_OR &&
		    elements[i]->query != BOOK_QUERY_SUB_END)
			return FALSE;
	}

	/* If there were no non-aux fields being queried, don't bother */
	return non_aux_fields != 0;
}

static EbSqlRowFunc
ebsql_generate_autocomplete_query (EBookSqlite *ebsql,
				   GString *string,
				   SearchType search_type,
				   PreflightContext *context,
				   GError **error)
{
	QueryElement **elements;
	gint n_elements, i;
	guint64 aux_mask = context->aux_mask;
	guint64 left_join_mask = context->left_join_mask;
	EbSqlRowFunc callback;
	gboolean first = TRUE;

	elements = (QueryElement **) context->constraints->pdata;
	n_elements = context->constraints->len;

	/* First the queries which use aux tables. */
	for (i = 0; i < n_elements; i++) {
		GenerateFieldTest generate_test_func = NULL;
		QueryFieldTest *test;
		gint aux_index;

		if (elements[i]->query == BOOK_QUERY_SUB_OR ||
		    elements[i]->query == BOOK_QUERY_SUB_END)
			continue;

		test = (QueryFieldTest *) elements[i];
		if (test->field->type != E_TYPE_CONTACT_ATTR_LIST)
			continue;

		aux_index = summary_field_get_index (ebsql, test->field_id);
		g_warn_if_fail (aux_index >= 0 && aux_index < EBSQL_MAX_SUMMARY_FIELDS);

		/* Just to mute a compiler warning when aux_index == -1 */
		aux_index = ABS (aux_index);

		context->aux_mask = (1 << aux_index);
		context->left_join_mask = 0;

		callback = ebsql_generate_select (ebsql, string, search_type, context, error);
		g_string_append (string, " WHERE ");
		context->aux_mask = aux_mask;
		context->left_join_mask = left_join_mask;
		if (!callback)
			return NULL;

		generate_test_func = field_test_func_table[test->query];
		generate_test_func (ebsql, string, test);

		g_string_append (string, " UNION ");
	}
	/* Finally, generate the SELECT for the primary fields. */
	context->aux_mask = 0;
	callback = ebsql_generate_select (ebsql, string, search_type, context, error);
	context->aux_mask = aux_mask;
	if (!callback)
		return NULL;

	g_string_append (string, " WHERE ");

	for (i = 0; i < n_elements; i++) {
		GenerateFieldTest generate_test_func = NULL;
		QueryFieldTest *test;

		if (elements[i]->query == BOOK_QUERY_SUB_OR ||
		    elements[i]->query == BOOK_QUERY_SUB_END)
			continue;

		test = (QueryFieldTest *) elements[i];
		if (test->field->type == E_TYPE_CONTACT_ATTR_LIST)
			continue;

		if (!first)
			g_string_append (string, " OR ");
		else
			first = FALSE;

		generate_test_func = field_test_func_table[test->query];
		generate_test_func (ebsql, string, test);
	}

	return callback;
}
static gboolean
ebsql_do_search_query (EBookSqlite *ebsql,
                       PreflightContext *context,
                       const gchar *sexp,
                       SearchType search_type,
                       GSList **return_data,
                       GCancellable *cancellable,
                       GError **error)
{
	GString *string;
	EbSqlRowFunc callback = NULL;
	gboolean success = FALSE;

	/* We might calculate a reasonable estimation of bytes
	 * during the preflight checks */
	string = g_string_sized_new (GENERATED_QUERY_BYTES);

	/* Extra special case. For the common case of the email composer's
	   addressbook autocompletion, we really want the most optimal query.
	   So check for it and use a basically hand-crafted one. */
        if (ebsql_is_autocomplete_query(context)) {
		callback = ebsql_generate_autocomplete_query (ebsql, string, search_type, context, error);
	} else {
		/* Generate the leading SELECT statement */
		callback = ebsql_generate_select (
						  ebsql, string, search_type, context, error);

		if (callback &&
		    EBSQL_STATUS_GEN_CONSTRAINTS (context->status)) {
			/*
			 * Now generate the search expression on the main contacts table
			 */
			g_string_append (string, " WHERE ");
			ebsql_generate_constraints (
				ebsql, string, context->constraints, sexp);
		}
	}

	if (callback)
		success = ebsql_exec (
			ebsql, string->str,
			callback, return_data,
			cancellable, error);

	g_string_free (string, TRUE);

	return success;
}

/* ebsql_search_query:
 * @ebsql: An EBookSqlite
 * @sexp: The search expression, or NULL for all contacts
 * @search_type: Indicates what kind of data should be returned
 * @return_data: A list of data fetched from the DB, as specified by 'search_type'
 * @error: Location to store any error which may have occurred
 *
 * This is the main common entry point for querying contacts.
 *
 * If the query cannot be satisfied with the summary, then
 * a fallback will automatically be used.
 */
static gboolean
ebsql_search_query (EBookSqlite *ebsql,
                    const gchar *sexp,
                    SearchType search_type,
                    GSList **return_data,
                    GCancellable *cancellable,
                    GError **error)
{
	PreflightContext context = PREFLIGHT_CONTEXT_INIT;
	gboolean success = FALSE;

	/* Now start with the query preflighting */
	query_preflight (&context, ebsql, sexp);

	switch (context.status) {
	case PREFLIGHT_OK:
	case PREFLIGHT_LIST_ALL:
	case PREFLIGHT_NOT_SUMMARIZED:
		/* No errors, let's really search */
		success = ebsql_do_search_query (
			ebsql, &context, sexp,
			search_type, return_data,
			cancellable, error);
		break;

	case PREFLIGHT_INVALID:
		EBSQL_SET_ERROR (
			error,
			E_BOOK_SQLITE_ERROR_INVALID_QUERY,
			_("Invalid query: %s"), sexp);
		break;

	case PREFLIGHT_UNSUPPORTED:
		EBSQL_SET_ERROR_LITERAL (
			error,
			E_BOOK_SQLITE_ERROR_UNSUPPORTED_QUERY,
			_("Query contained unsupported elements"));
		break;
	}

	preflight_context_clear (&context);

	return success;
}

/******************************************************************
 *                    EbSqlCursor Implementation                  *
 ******************************************************************/
typedef struct _CursorState CursorState;

struct _CursorState {
	gchar            **values;    /* The current cursor position, results will be returned after this position */
	gchar             *last_uid;  /* The current cursor contact UID position, used as a tie breaker */
	EbSqlCursorOrigin  position;  /* The position is updated with the cursor state and is used to distinguish
				       * between the beginning and the ending of the cursor's contact list.
				       * While the cursor is in a non-null state, the position will be 
				       * EBSQL_CURSOR_ORIGIN_CURRENT.
				       */
};

struct _EbSqlCursor {
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

static CursorState *cursor_state_copy             (EbSqlCursor          *cursor,
						   CursorState          *state);
static void         cursor_state_free             (EbSqlCursor          *cursor,
						   CursorState          *state);
static void         cursor_state_clear            (EbSqlCursor          *cursor,
						   CursorState          *state,
						   EbSqlCursorOrigin     position);
static void         cursor_state_set_from_contact (EBookSqlite          *ebsql,
						   EbSqlCursor          *cursor,
						   CursorState          *state,
						   EContact             *contact);
static void         cursor_state_set_from_vcard   (EBookSqlite          *ebsql,
						   EbSqlCursor          *cursor,
						   CursorState          *state,
						   const gchar          *vcard);

static CursorState *
cursor_state_copy (EbSqlCursor *cursor,
                   CursorState *state)
{
	CursorState *copy;
	gint i;

	copy = g_slice_new0 (CursorState);
	copy->values = g_new0 (gchar *, cursor->n_sort_fields);

	for (i = 0; i < cursor->n_sort_fields; i++)
		copy->values[i] = g_strdup (state->values[i]);

	copy->last_uid = g_strdup (state->last_uid);
	copy->position = state->position;

	return copy;
}

static void
cursor_state_free (EbSqlCursor *cursor,
                   CursorState *state)
{
	if (state) {
		cursor_state_clear (cursor, state, EBSQL_CURSOR_ORIGIN_BEGIN);
		g_free (state->values);
		g_slice_free (CursorState, state);
	}
}

static void
cursor_state_clear (EbSqlCursor *cursor,
                    CursorState *state,
                    EbSqlCursorOrigin position)
{
	gint i;

	for (i = 0; i < cursor->n_sort_fields; i++) {
		g_free (state->values[i]);
		state->values[i] = NULL;
	}

	g_free (state->last_uid);
	state->last_uid = NULL;
	state->position = position;
}

static void
cursor_state_set_from_contact (EBookSqlite *ebsql,
                               EbSqlCursor *cursor,
                               CursorState *state,
                               EContact *contact)
{
	gint i;

	cursor_state_clear (cursor, state, EBSQL_CURSOR_ORIGIN_BEGIN);

	for (i = 0; i < cursor->n_sort_fields; i++) {
		const gchar *string = e_contact_get_const (contact, cursor->sort_fields[i]);
		SummaryField *field;
		gchar *sort_key;

		if (string)
			sort_key = e_collator_generate_key (
				ebsql->priv->collator,
				string, NULL);
		else
			sort_key = g_strdup ("");

		field = summary_field_get (ebsql, cursor->sort_fields[i]);

		if (field && (field->index & INDEX_FLAG (SORT_KEY)) != 0) {
			state->values[i] = sort_key;
		} else {
			state->values[i] = ebsql_encode_vcard_sort_key (sort_key);
			g_free (sort_key);
		}
	}

	state->last_uid = e_contact_get (contact, E_CONTACT_UID);
	state->position = EBSQL_CURSOR_ORIGIN_CURRENT;
}

static void
cursor_state_set_from_vcard (EBookSqlite *ebsql,
                             EbSqlCursor *cursor,
                             CursorState *state,
                             const gchar *vcard)
{
	EContact *contact;

	contact = e_contact_new_from_vcard (vcard);
	cursor_state_set_from_contact (ebsql, cursor, state, contact);
	g_object_unref (contact);
}

static gboolean
ebsql_cursor_setup_query (EBookSqlite *ebsql,
                          EbSqlCursor *cursor,
                          const gchar *sexp,
                          GError **error)
{
	PreflightContext context = PREFLIGHT_CONTEXT_INIT;
	GString *string;

	/* Preflighting and error checking */
	if (sexp) {
		query_preflight (&context, ebsql, sexp);

		if (context.status > PREFLIGHT_NOT_SUMMARIZED) {
			EBSQL_SET_ERROR_LITERAL (
				error,
				E_BOOK_SQLITE_ERROR_INVALID_QUERY,
				_("Invalid query for EbSqlCursor"));

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
	ebsql_generate_select (ebsql, string, SEARCH_FULL, &context, NULL);
	cursor->select_vcards = g_string_free (string, FALSE);

	string = g_string_new ("");
	ebsql_generate_select (ebsql, string, SEARCH_COUNT, &context, NULL);
	cursor->select_count = g_string_free (string, FALSE);

	if (sexp == NULL || context.status == PREFLIGHT_LIST_ALL) {
		cursor->query = NULL;
		cursor->sexp = NULL;
	} else {
		/* Generate the constraints for our queries
		 */
		string = g_string_new (NULL);
		ebsql_generate_constraints (
			ebsql, string, context.constraints, sexp);
		cursor->query = g_string_free (string, FALSE);
		cursor->sexp = e_book_backend_sexp_new (sexp);
	}

	preflight_context_clear (&context);

	return TRUE;
}

static gchar *
ebsql_cursor_order_by_fragment (EBookSqlite *ebsql,
                                const EContactField *sort_fields,
                                const EBookCursorSortType *sort_types,
                                guint n_sort_fields,
                                gboolean reverse)
{
	GString *string;
	gint i;

	string = g_string_new ("ORDER BY ");

	for (i = 0; i < n_sort_fields; i++) {
		SummaryField *field = summary_field_get (ebsql, sort_fields[i]);

		if (i > 0)
			g_string_append (string, ", ");

		if (field &&
		    (field->index & INDEX_FLAG (SORT_KEY)) != 0) {
			g_string_append (string, "summary.");
			g_string_append (string, field->dbname);
			g_string_append (string, "_" EBSQL_SUFFIX_SORT_KEY " ");
		} else {
			g_string_append (string, EBSQL_VCARD_FRAGMENT (ebsql));
			g_string_append (string, " COLLATE ");
			g_string_append (string, EBSQL_COLLATE_PREFIX);
			g_string_append (string, e_contact_field_name (sort_fields[i]));
			g_string_append_c (string, ' ');
		}

		if (reverse)
			g_string_append (string, (sort_types[i] == E_BOOK_CURSOR_SORT_ASCENDING ? "DESC" : "ASC"));
		else
			g_string_append (string, (sort_types[i] == E_BOOK_CURSOR_SORT_ASCENDING ? "ASC" : "DESC"));
	}

	/* Also order the UID, since it's our tie breaker */
	if (n_sort_fields > 0)
		g_string_append (string, ", ");

	g_string_append (string, "summary.uid ");
	g_string_append (string, reverse ? "DESC" : "ASC");

	return g_string_free (string, FALSE);
}

static EbSqlCursor *
ebsql_cursor_new (EBookSqlite *ebsql,
                  const gchar *sexp,
                  const EContactField *sort_fields,
                  const EBookCursorSortType *sort_types,
                  guint n_sort_fields)
{
	EbSqlCursor *cursor = g_slice_new0 (EbSqlCursor);

	cursor->order = ebsql_cursor_order_by_fragment (
		ebsql, sort_fields, sort_types, n_sort_fields, FALSE);
	cursor->reverse_order = ebsql_cursor_order_by_fragment (
		ebsql, sort_fields, sort_types, n_sort_fields, TRUE);

	/* Sort parameters */
	cursor->n_sort_fields = n_sort_fields;
	cursor->sort_fields = g_memdup (sort_fields, sizeof (EContactField) * n_sort_fields);
	cursor->sort_types = g_memdup (sort_types,  sizeof (EBookCursorSortType) * n_sort_fields);

	/* Cursor state */
	cursor->state.values = g_new0 (gchar *, n_sort_fields);
	cursor->state.last_uid = NULL;
	cursor->state.position = EBSQL_CURSOR_ORIGIN_BEGIN;

	return cursor;
}

static void
ebsql_cursor_free (EbSqlCursor *cursor)
{
	if (cursor) {
		cursor_state_clear (cursor, &(cursor->state), EBSQL_CURSOR_ORIGIN_BEGIN);
		g_free (cursor->state.values);

		g_clear_object (&(cursor->sexp));
		g_free (cursor->select_vcards);
		g_free (cursor->select_count);
		g_free (cursor->query);
		g_free (cursor->order);
		g_free (cursor->reverse_order);
		g_free (cursor->sort_fields);
		g_free (cursor->sort_types);

		g_slice_free (EbSqlCursor, cursor);
	}
}

#define GREATER_OR_LESS(cursor, idx, reverse) \
	(reverse ? \
	 (((EbSqlCursor *) cursor)->sort_types[idx] == E_BOOK_CURSOR_SORT_ASCENDING ? '<' : '>') : \
	 (((EbSqlCursor *) cursor)->sort_types[idx] == E_BOOK_CURSOR_SORT_ASCENDING ? '>' : '<'))

static inline void
ebsql_cursor_format_equality (EBookSqlite *ebsql,
                              GString *string,
                              EContactField field_id,
                              const gchar *value,
                              gchar equality)
{
	SummaryField *field = summary_field_get (ebsql, field_id);

	if (field &&
	    (field->index & INDEX_FLAG (SORT_KEY)) != 0) {

		g_string_append (string, "summary.");
		g_string_append (string, field->dbname);
		g_string_append (string, "_" EBSQL_SUFFIX_SORT_KEY " ");

		ebsql_string_append_printf (string, "%c %Q", equality, value);

	} else {
		ebsql_string_append_printf (
			string, "(%s %c %Q ",
			EBSQL_VCARD_FRAGMENT (ebsql),
			equality, value);

		g_string_append (string, "COLLATE " EBSQL_COLLATE_PREFIX);
		g_string_append (string, e_contact_field_name (field_id));
		g_string_append_c (string, ')');
	}
}

static gchar *
ebsql_cursor_constraints (EBookSqlite *ebsql,
                          EbSqlCursor *cursor,
                          CursorState *state,
                          gboolean reverse,
                          gboolean include_current_uid)
{
	GString *string;
	gint i, j;

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

	for (i = 0; i <= cursor->n_sort_fields; i++) {

		/* Break once we hit a NULL value */
		if ((i < cursor->n_sort_fields && state->values[i] == NULL) ||
		    (i == cursor->n_sort_fields && state->last_uid == NULL))
			break;

		/* Between each qualifier, add an 'OR' */
		if (i > 0)
			g_string_append (string, " OR ");

		/* Begin qualifier */
		g_string_append_c (string, '(');

		/* Create the '=' statements leading up to the current tie breaker */
		for (j = 0; j < i; j++) {
			ebsql_cursor_format_equality (ebsql, string,
						      cursor->sort_fields[j],
						      state->values[j], '=');
			g_string_append (string, " AND ");
		}

		if (i == cursor->n_sort_fields) {

			/* The 'include_current_uid' clause is used for calculating
			 * the current position of the cursor, inclusive of the
			 * current position.
			 */
			if (include_current_uid)
				g_string_append_c (string, '(');

			/* Append the UID tie breaker */
			ebsql_string_append_printf (
				string,
				"summary.uid %c %Q",
				reverse ? '<' : '>',
				state->last_uid);

			if (include_current_uid)
				ebsql_string_append_printf (
					string,
					" OR summary.uid = %Q)",
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
				 ((i + 1 < cursor->n_sort_fields && state->values[i + 1] == NULL) ||
				  (i + 1 == cursor->n_sort_fields && state->last_uid == NULL)));

			if (include_exact_match)
				g_string_append_c (string, '(');

			/* Append the final qualifier for this field */
			ebsql_cursor_format_equality (ebsql, string,
						      cursor->sort_fields[i],
						      state->values[i],
						      GREATER_OR_LESS (cursor, i, reverse));

			if (include_exact_match) {
				g_string_append (string, " OR ");
				ebsql_cursor_format_equality (ebsql, string,
							      cursor->sort_fields[i],
							      state->values[i], '=');
				g_string_append_c (string, ')');
			}
		}

		/* End qualifier */
		g_string_append_c (string, ')');
	}

	return g_string_free (string, FALSE);
}

static gboolean
cursor_count_total_locked (EBookSqlite *ebsql,
                           EbSqlCursor *cursor,
                           gint *total,
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
	success = ebsql_exec (ebsql, query->str, get_count_cb, total, NULL, error);

	g_string_free (query, TRUE);

	return success;
}

static gboolean
cursor_count_position_locked (EBookSqlite *ebsql,
                              EbSqlCursor *cursor,
                              gint *position,
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
		constraints = ebsql_cursor_constraints (
			ebsql, cursor, &(cursor->state), TRUE, TRUE);

		g_string_append_c (query, '(');
		g_string_append (query, constraints);
		g_string_append_c (query, ')');

		g_free (constraints);
	}

	/* Execute the query */
	success = ebsql_exec (ebsql, query->str, get_count_cb, position, NULL, error);

	g_string_free (query, TRUE);

	return success;
}

/**********************************************************
 *                     GObjectClass                       *
 **********************************************************/
static void
e_book_sqlite_dispose (GObject *object)
{
	EBookSqlite *ebsql = E_BOOK_SQLITE (object);

	ebsql_unregister_from_hash (ebsql);

	/* Chain up to parent's dispose() method. */
	G_OBJECT_CLASS (e_book_sqlite_parent_class)->dispose (object);
}

static void
e_book_sqlite_finalize (GObject *object)
{
	EBookSqlite *ebsql = E_BOOK_SQLITE (object);
	EBookSqlitePrivate *priv = ebsql->priv;

	summary_fields_array_free (
		priv->summary_fields,
		priv->n_summary_fields);

	g_free (priv->folderid);
	g_free (priv->path);
	g_free (priv->locale);
	g_free (priv->region_code);

	if (priv->collator)
		e_collator_unref (priv->collator);

	g_clear_object (&priv->source);

	g_mutex_clear (&priv->lock);
	g_mutex_clear (&priv->updates_lock);

	if (priv->multi_deletes)
		g_hash_table_destroy (priv->multi_deletes);

	if (priv->multi_inserts)
		g_hash_table_destroy (priv->multi_inserts);

	if (priv->user_data && priv->user_data_destroy)
		priv->user_data_destroy (priv->user_data);

	sqlite3_finalize (priv->insert_stmt);
	sqlite3_finalize (priv->replace_stmt);
	sqlite3_close (priv->db);

	EBSQL_NOTE (REF_COUNTS, g_printerr ("EBookSqlite finalized\n"));

	/* Chain up to parent's finalize() method. */
	G_OBJECT_CLASS (e_book_sqlite_parent_class)->finalize (object);
}

static void
e_book_sqlite_constructed (GObject *object)
{
	/* Chain up to parent's constructed() method. */
	G_OBJECT_CLASS (e_book_sqlite_parent_class)->constructed (object);

	e_extensible_load_extensions (E_EXTENSIBLE (object));
}

static gboolean
ebsql_signals_accumulator (GSignalInvocationHint *ihint,
			   GValue *return_accu,
			   const GValue *handler_return,
			   gpointer data)
{
	gboolean handler_result;

	handler_result = g_value_get_boolean (handler_return);
	g_value_set_boolean (return_accu, handler_result);

	return handler_result;
}

static gboolean
ebsql_before_insert_contact_default (EBookSqlite *ebsql,
				     gpointer db,
				     EContact *contact,
				     const gchar *extra,
				     gboolean replace,
				     GCancellable *cancellable,
				     GError **error)
{
	return TRUE;
}

static gboolean
ebsql_before_remove_contact_default (EBookSqlite *ebsql,
				     gpointer db,
				     const gchar *contact_uid,
				     GCancellable *cancellable,
				     GError **error)
{
	return TRUE;
}

static void
e_book_sqlite_class_init (EBookSqliteClass *class)
{
	GObjectClass *object_class;

	g_type_class_add_private (class, sizeof (EBookSqlitePrivate));

	object_class = G_OBJECT_CLASS (class);
	object_class->dispose = e_book_sqlite_dispose;
	object_class->finalize = e_book_sqlite_finalize;
	object_class->constructed = e_book_sqlite_constructed;

	class->before_insert_contact = ebsql_before_insert_contact_default;
	class->before_remove_contact = ebsql_before_remove_contact_default;

	/* Parse the EBSQL_DEBUG environment variable */
	ebsql_init_debug ();

	signals[BEFORE_INSERT_CONTACT] = g_signal_new (
		"before-insert-contact",
		G_OBJECT_CLASS_TYPE (class),
		G_SIGNAL_RUN_LAST,
		G_STRUCT_OFFSET (EBookSqliteClass, before_insert_contact),
		ebsql_signals_accumulator,
		NULL,
		g_cclosure_marshal_generic,
		G_TYPE_BOOLEAN, 6,
		G_TYPE_POINTER,
		G_TYPE_OBJECT,
		G_TYPE_STRING,
		G_TYPE_BOOLEAN,
		G_TYPE_OBJECT,
		G_TYPE_POINTER);

	signals[BEFORE_REMOVE_CONTACT] = g_signal_new (
		"before-remove-contact",
		G_OBJECT_CLASS_TYPE (class),
		G_SIGNAL_RUN_LAST,
		G_STRUCT_OFFSET (EBookSqliteClass, before_remove_contact),
		ebsql_signals_accumulator,
		NULL,
		g_cclosure_marshal_generic,
		G_TYPE_BOOLEAN, 4,
		G_TYPE_POINTER,
		G_TYPE_STRING,
		G_TYPE_OBJECT,
		G_TYPE_POINTER);
}

static void
e_book_sqlite_init (EBookSqlite *ebsql)
{
	ebsql->priv = E_BOOK_SQLITE_GET_PRIVATE (ebsql);

	g_mutex_init (&ebsql->priv->lock);
	g_mutex_init (&ebsql->priv->updates_lock);
}

/**********************************************************
 *                          API                           *
 **********************************************************/
static EBookSqlite *
ebsql_new_default (const gchar *path,
		   ESource *source,
                   EbSqlVCardCallback vcard_callback,
                   EbSqlChangeCallback change_callback,
                   gpointer user_data,
                   GDestroyNotify user_data_destroy,
                   GCancellable *cancellable,
                   GError **error)
{
	EBookSqlite *ebsql;
	GArray *summary_fields;
	gint i;

	/* Create the default summary structs */
	summary_fields = g_array_new (FALSE, FALSE, sizeof (SummaryField));
	for (i = 0; i < G_N_ELEMENTS (default_summary_fields); i++)
		summary_field_append (summary_fields, DEFAULT_FOLDER_ID, default_summary_fields[i], NULL);

	/* Add the default index flags */
	summary_fields_add_indexes (
		summary_fields,
		default_indexed_fields,
		default_index_types,
		G_N_ELEMENTS (default_indexed_fields));

	ebsql = ebsql_new_internal (
		path, source,
		vcard_callback, change_callback,
		user_data, user_data_destroy,
		(SummaryField *) summary_fields->data,
		summary_fields->len,
		cancellable, error);

	g_array_free (summary_fields, FALSE);

	return ebsql;
}

/**
 * e_book_sqlite_new:
 * @path: location to load or create the new database
 * @source: an optional #ESource, associated with the #EBookSqlite, or %NULL
 * @cancellable: (allow-none): A #GCancellable
 * @error: (allow-none): A location to store any error that may have occurred.
 *
 * Creates a new #EBookSqlite with the default summary configuration.
 *
 * Aside from the manditory fields %E_CONTACT_UID, %E_CONTACT_REV,
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
 * the #EbSqlCursor interface, using the %E_BOOK_INDEX_SORT_KEY
 * index flag.
 *
 * Returns: (transfer full): A reference to a #EBookSqlite
 *
 * Since: 3.12
 **/
EBookSqlite *
e_book_sqlite_new (const gchar *path,
		   ESource *source,
                   GCancellable *cancellable,
                   GError **error)
{
	g_return_val_if_fail (path && path[0], NULL);

	return ebsql_new_default (path, source, NULL, NULL, NULL, NULL, cancellable, error);
}

/**
 * e_book_sqlite_new_full:
 * @path: location to load or create the new database
 * @source: an optional #ESource, associated with the #EBookSqlite, or %NULL
 * @setup: (allow-none): an #ESourceBackendSummarySetup describing how the summary should be setup, or %NULL to use the default
 * @vcard_callback: (allow-none) (scope async) (closure user_data): A function to resolve vcards
 * @change_callback: (allow-none) (scope async) (closure user_data): A function to catch notifications of vcard changes
 * @user_data: (allow-none): callback user data
 * @user_data_destroy: (allow-none): A function to free @user_data automatically when the created #EBookSqlite is destroyed.
 * @cancellable: (allow-none): A #GCancellable
 * @error: (allow-none): A location to store any error that may have occurred.
 *
 * Opens or creates a new addressbook at @path.
 *
 * Like e_book_sqlite_new(), but allows configuration of which contact fields
 * will be stored for quick reference in the summary. The configuration indicated by
 * @setup will only be taken into account when initially creating the underlying table,
 * further configurations will be ignored.
 *
 * The fields %E_CONTACT_UID and %E_CONTACT_REV are not optional,
 * they will be stored in the summary regardless of this function's parameters.
 * Only #EContactFields with the type #G_TYPE_STRING, #G_TYPE_BOOLEAN or
 * #E_TYPE_CONTACT_ATTR_LIST are currently supported.
 *
 * If @vcard_callback is specified, then vcards will not be stored by functions
 * such as e_book_sqlitedb_add_contact(). Instead @vcard_callback will be invoked
 * at any time the created #EBookSqlite requires a vcard, either as a fallback
 * for querying search expressions which cannot be satisfied with the summary
 * fields, or when reporting results from searches.
 *
 * If any error occurs and %NULL is returned, then the passed @user_data will
 * be automatically freed using the @user_data_destroy function, if specified.
 *
 * It is recommended to store all contact vcards in the #EBookSqlite addressbook
 * if at all possible, however in some cases the vcards must be stored in some
 * other storage.
 *
 * Returns: (transfer full): The newly created #EBookSqlite, or %NULL if opening or creating the addressbook failed.
 *
 * Since: 3.12
 **/
EBookSqlite *
e_book_sqlite_new_full (const gchar *path,
			ESource *source,
                        ESourceBackendSummarySetup *setup,
                        EbSqlVCardCallback vcard_callback,
                        EbSqlChangeCallback change_callback,
                        gpointer user_data,
                        GDestroyNotify user_data_destroy,
                        GCancellable *cancellable,
                        GError **error)
{
	EBookSqlite *ebsql = NULL;
	EContactField *fields;
	EContactField *indexed_fields;
	EBookIndexType *index_types = NULL;
	gboolean had_error = FALSE;
	GArray *summary_fields;
	gint n_fields = 0, n_indexed_fields = 0, i;

	g_return_val_if_fail (path && path[0], NULL);
	g_return_val_if_fail (setup == NULL || E_IS_SOURCE_BACKEND_SUMMARY_SETUP (setup), NULL);

	if (!setup)
		return ebsql_new_default (
			path,
			source,
			vcard_callback,
			change_callback,
			user_data,
			user_data_destroy,
			cancellable, error);

	fields = e_source_backend_summary_setup_get_summary_fields (setup, &n_fields);
	indexed_fields = e_source_backend_summary_setup_get_indexed_fields (setup, &index_types, &n_indexed_fields);

	/* No specified summary fields indicates the default summary configuration should be used */
	if (n_fields <= 0 || n_fields >= EBSQL_MAX_SUMMARY_FIELDS) {

		if (n_fields)
			g_warning (
				"EBookSqlite refused to create addressbook with over %d summary fields",
				EBSQL_MAX_SUMMARY_FIELDS);

		ebsql = ebsql_new_default (
			path,
			source,
			vcard_callback,
			change_callback,
			user_data,
			user_data_destroy,
			cancellable, error);
		g_free (fields);
		g_free (index_types);
		g_free (indexed_fields);

		return ebsql;
	}

	summary_fields = g_array_new (FALSE, FALSE, sizeof (SummaryField));

	/* Ensure the non-optional fields first */
	summary_field_append (summary_fields, DEFAULT_FOLDER_ID, E_CONTACT_UID, error);
	summary_field_append (summary_fields, DEFAULT_FOLDER_ID, E_CONTACT_REV, error);

	for (i = 0; i < n_fields; i++) {
		if (!summary_field_append (summary_fields, DEFAULT_FOLDER_ID, fields[i], error)) {
			had_error = TRUE;
			break;
		}
	}

	if (had_error) {
		gint n_sfields;
		SummaryField *sfields;

		/* Properly free the array */
		n_sfields = summary_fields->len;
		sfields = (SummaryField *) g_array_free (summary_fields, FALSE);
		summary_fields_array_free (sfields, n_sfields);

		g_free (fields);
		g_free (index_types);
		g_free (indexed_fields);

		if (user_data && user_data_destroy)
			user_data_destroy (user_data);

		return NULL;
	}

	/* Add the 'indexed' flag to the SummaryField structs */
	summary_fields_add_indexes (
		summary_fields, indexed_fields, index_types, n_indexed_fields);

	ebsql = ebsql_new_internal (
		path, source,
		vcard_callback, change_callback,
		user_data, user_data_destroy,
		(SummaryField *) summary_fields->data,
		summary_fields->len,
		cancellable, error);

	g_free (fields);
	g_free (index_types);
	g_free (indexed_fields);
	g_array_free (summary_fields, FALSE);

	return ebsql;
}

/**
 * e_book_sqlite_lock:
 * @ebsql: An #EBookSqlite
 * @lock_type: The #EbSqlLockType to acquire
 * @cancellable: (allow-none): A #GCancellable
 * @error: (allow-none): A location to store any error that may have occurred.
 *
 * Obtains an exclusive lock on @ebsql and starts a transaction.
 *
 * This should be called if you need to access @ebsql multiple times while
 * ensuring an atomic transaction. End this transaction with e_book_sqlite_unlock().
 *
 * If @cancellable is specified, then @ebsql will retain a reference to it until
 * e_book_sqlite_unlock() is called. Any accesses to @ebsql with the lock held
 * are expected to have the same @cancellable specified, or %NULL.
 *
 * <note><para>Aside from ensuring atomicity of transactions, this function will hold a mutex
 * which will cause further calls to e_book_sqlite_lock() to block. If you are accessing
 * @ebsql from multiple threads, then any interactions with @ebsql should be nested in calls
 * to e_book_sqlite_lock() and e_book_sqlite_unlock().</para></note>
 *
 * Returns: %TRUE on success, otherwise %FALSE is returned and @error is set appropriately.
 *
 * Since: 3.12
 **/
gboolean
e_book_sqlite_lock (EBookSqlite *ebsql,
                    EbSqlLockType lock_type,
                    GCancellable *cancellable,
                    GError **error)
{
	gboolean success;

	g_return_val_if_fail (E_IS_BOOK_SQLITE (ebsql), FALSE);

	EBSQL_LOCK_MUTEX (&ebsql->priv->updates_lock);

	/* Here, after obtaining the outer facing transaction lock, we need
	 * to assert that there is no cancellable already set */
	if (ebsql->priv->cancel != NULL) {
		/* This should never happen, if it does it's a bug
		 * in this code, not the calling code
		 */
		g_warn_if_reached ();
		EBSQL_UNLOCK_MUTEX (&ebsql->priv->updates_lock);
		return FALSE;
	}

	EBSQL_LOCK_MUTEX (&ebsql->priv->lock);

	/* Here, after obtaining the regular lock, we need to assert that we are
	 * the toplevel transaction */
	if (ebsql->priv->in_transaction != 0) {
		g_warn_if_reached ();
		EBSQL_LOCK_MUTEX (&ebsql->priv->lock);
		EBSQL_UNLOCK_MUTEX (&ebsql->priv->updates_lock);
		return FALSE;
	}

	success = ebsql_start_transaction (ebsql, lock_type, cancellable, error);
	EBSQL_UNLOCK_MUTEX (&ebsql->priv->lock);

	/* If we failed to start the transaction, we don't hold the lock */
	if (!success)
		EBSQL_UNLOCK_MUTEX (&ebsql->priv->updates_lock);

	return success;
}

/**
 * e_book_sqlite_unlock:
 * @ebsql: An #EBookSqlite
 * @action: Which #EbSqlUnlockAction to take while unlocking
 * @error: (allow-none): A location to store any error that may have occurred.
 *
 * Releases an exclusive on @ebsql and finishes a transaction previously
 * started with e_book_sqlite_lock_updates().
 *
 * <note><para>If this fails, the lock on @ebsql is still released and @error will
 * be set to indicate why the transaction or rollback failed.</para></note>
 *
 * Returns: %TRUE on success, otherwise %FALSE is returned and @error is set appropriately.
 *
 * Since: 3.12
 **/
gboolean
e_book_sqlite_unlock (EBookSqlite *ebsql,
                      EbSqlUnlockAction action,
                      GError **error)
{
	gboolean success = FALSE;

	g_return_val_if_fail (E_IS_BOOK_SQLITE (ebsql), FALSE);

	EBSQL_LOCK_MUTEX (&ebsql->priv->lock);

	switch (action) {
	case EBSQL_UNLOCK_NONE:
	case EBSQL_UNLOCK_COMMIT:
		success = ebsql_commit_transaction (ebsql, error);
		break;
	case EBSQL_UNLOCK_ROLLBACK:
		success = ebsql_rollback_transaction (ebsql, error);
		break;
	}

	EBSQL_UNLOCK_MUTEX (&ebsql->priv->lock);

	EBSQL_UNLOCK_MUTEX (&ebsql->priv->updates_lock);

	return success;
}

/**
 * e_book_sqlite_ref_collator:
 * @ebsql: An #EBookSqlite
 *
 * References the currently active #ECollator for @ebsql,
 * use e_collator_unref() when finished using the returned collator.
 *
 * Note that the active collator will change with the active locale setting.
 *
 * Returns: (transfer full): A reference to the active collator.
 *
 * Since: 3.12
 */
ECollator *
e_book_sqlite_ref_collator (EBookSqlite *ebsql)
{
	g_return_val_if_fail (E_IS_BOOK_SQLITE (ebsql), NULL);

	return e_collator_ref (ebsql->priv->collator);
}

/**
 * e_book_sqlite_ref_source:
 * @ebsql: An #EBookSqlite
 *
 * References the #ESource to which @ebsql is paired,
 * use g_object_unref() when finished using the source.
 * It can be %NULL in some cases, like when running tests.
 *
 * Returns: (transfer full): A reference to the #ESource to which @ebsql
 * is paired, or %NULL.
 *
 * Since: 3.16
*/
ESource *
e_book_sqlite_ref_source (EBookSqlite *ebsql)
{
	g_return_val_if_fail (E_IS_BOOK_SQLITE (ebsql), NULL);

	if (!ebsql->priv->source)
		return NULL;

	return g_object_ref (ebsql->priv->source);
}

/**
 * e_book_sqlitedb_add_contact:
 * @ebsql: An #EBookSqlite
 * @contact: EContact to be added
 * @extra: Extra data to store in association with this contact
 * @replace: Whether this contact should replace another contact with the same UID.
 * @cancellable: (allow-none): A #GCancellable
 * @error: (allow-none): A location to store any error that may have occurred.
 *
 * This is a convenience wrapper for e_book_sqlite_add_contacts(),
 * which is the preferred means to add or modify multiple contacts when possible.
 *
 * Returns: %TRUE on success, otherwise %FALSE is returned and @error is set appropriately.
 *
 * Since: 3.12
 **/
gboolean
e_book_sqlite_add_contact (EBookSqlite *ebsql,
                           EContact *contact,
                           const gchar *extra,
                           gboolean replace,
                           GCancellable *cancellable,
                           GError **error)
{
	GSList l;
	GSList el;

	g_return_val_if_fail (E_IS_BOOK_SQLITE (ebsql), FALSE);
	g_return_val_if_fail (E_IS_CONTACT (contact), FALSE);

	l.data = contact;
	l.next = NULL;

	el.data = (gpointer) extra;
	el.next = NULL;

	return e_book_sqlite_add_contacts (ebsql, &l, &el, replace, cancellable, error);
}

/**
 * e_book_sqlite_new_contacts:
 * @ebsql: An #EBookSqlite
 * @contacts: (element-type EContact): A list of contacts to add to @ebsql
 * @extra: (allow-none) (element-type utf8): A list of extra data to store in association with this contact
 * @replace: Whether this contact should replace another contact with the same UID.
 * @cancellable: (allow-none): A #GCancellable
 * @error: (allow-none): A location to store any error that may have occurred.
 *
 * Adds or replaces contacts in @ebsql. If @replace_existing is specified then existing
 * contacts with the same UID will be replaced, otherwise adding an existing contact
 * will return an error.
 *
 * If @extra is specified, it must have an equal length as the @contacts list. Each element
 * from the @extra list will be stored in association with it's corresponding contact
 * in the @contacts list.
 *
 * Returns: %TRUE on success, otherwise %FALSE is returned and @error is set appropriately.
 *
 * Since: 3.12
 **/
gboolean
e_book_sqlite_add_contacts (EBookSqlite *ebsql,
                            GSList *contacts,
                            GSList *extra,
                            gboolean replace,
                            GCancellable *cancellable,
                            GError **error)
{
	GSList *l, *ll;
	gboolean success = TRUE;

	g_return_val_if_fail (E_IS_BOOK_SQLITE (ebsql), FALSE);
	g_return_val_if_fail (contacts != NULL, FALSE);
	g_return_val_if_fail (extra == NULL ||
			      g_slist_length (extra) == g_slist_length (contacts), FALSE);

	EBSQL_LOCK_OR_RETURN (ebsql, cancellable, FALSE);

	if (!ebsql_start_transaction (ebsql, EBSQL_LOCK_WRITE, cancellable, error)) {
		EBSQL_UNLOCK_MUTEX (&ebsql->priv->lock);
		return FALSE;
	}

	for (l = contacts, ll = extra;
	     success && l != NULL;
	     l = l->next, ll = ll ? ll->next : NULL) {
		EContact *contact = (EContact *) l->data;
		const gchar *extra_data = NULL;

		if (ll)
			extra_data = (const gchar *) ll->data;

		g_signal_emit (ebsql,
			       signals[BEFORE_INSERT_CONTACT],
			       0,
			       ebsql->priv->db,
			       contact, extra_data,
			       replace,
			       cancellable, error,
			       &success);
		if (!success)
			break;

		success = ebsql_insert_contact (
			ebsql,
			EBSQL_CHANGE_CONTACT_ADDED,
			contact, NULL, extra_data,
			replace, error);
	}

	if (success)
		success = ebsql_commit_transaction (ebsql, error);
	else
		/* The GError is already set. */
		ebsql_rollback_transaction (ebsql, NULL);

	EBSQL_UNLOCK_MUTEX (&ebsql->priv->lock);

	return success;
}

/**
 * e_book_sqlite_remove_contact:
 * @ebsql: An #EBookSqlite
 * @uid: the uid of the contact to remove
 * @cancellable: (allow-none): A #GCancellable
 * @error: (allow-none): A location to store any error that may have occurred.
 *
 * Removes the contact indicated by @uid from @ebsql.
 *
 * Returns: %TRUE on success, otherwise %FALSE is returned and @error is set appropriately.
 *
 * Since: 3.12
 **/
gboolean
e_book_sqlite_remove_contact (EBookSqlite *ebsql,
                              const gchar *uid,
                              GCancellable *cancellable,
                              GError **error)
{
	GSList l;

	g_return_val_if_fail (E_IS_BOOK_SQLITE (ebsql), FALSE);
	g_return_val_if_fail (uid != NULL, FALSE);

	l.data = (gchar *) uid; /* Won't modify it, I promise :) */
	l.next = NULL;

	return e_book_sqlite_remove_contacts (
		ebsql, &l, cancellable, error);
}

static gchar *
generate_delete_stmt (const gchar *table,
                      GSList *uids)
{
	GString *str = g_string_new (NULL);
	GSList  *l;

	ebsql_string_append_printf (str, "DELETE FROM %Q WHERE uid IN (", table);

	for (l = uids; l; l = l->next) {
		const gchar *uid = (const gchar *) l->data;

		/* First uid with no comma */
		if (l != uids)
			g_string_append_printf (str, ", ");

		ebsql_string_append_printf (str, "%Q", uid);
	}

	g_string_append_c (str, ')');

	return g_string_free (str, FALSE);
}

/**
 * e_book_sqlite_remove_contacts:
 * @ebsql: An #EBookSqlite
 * @uids: a #GSList of uids indicating which contacts to remove
 * @cancellable: (allow-none): A #GCancellable
 * @error: (allow-none): A location to store any error that may have occurred.
 *
 * Removes the contacts indicated by @uids from @ebsql.
 *
 * Returns: %TRUE on success, otherwise %FALSE is returned and @error is set appropriately.
 *
 * Since: 3.12
 **/
gboolean
e_book_sqlite_remove_contacts (EBookSqlite *ebsql,
                               GSList *uids,
                               GCancellable *cancellable,
                               GError **error)
{
	gboolean success = TRUE;
	gint i;
	gchar *stmt;
	const gchar *contact_uid;
	GSList *l = NULL;

	g_return_val_if_fail (E_IS_BOOK_SQLITE (ebsql), FALSE);
	g_return_val_if_fail (uids != NULL, FALSE);

	EBSQL_LOCK_OR_RETURN (ebsql, cancellable, FALSE);

	if (!ebsql_start_transaction (ebsql, EBSQL_LOCK_WRITE, cancellable, error)) {
		EBSQL_UNLOCK_MUTEX (&ebsql->priv->lock);
		return FALSE;
	}

	for (l = uids; success && l; l = l->next) {
		contact_uid = (const gchar *) l->data;
		g_signal_emit (ebsql,
			       signals[BEFORE_REMOVE_CONTACT],
			       0,
			       ebsql->priv->db,
			       contact_uid,
			       cancellable, error,
			       &success);
	}

	/* Delete data from the auxiliary tables first */
	for (i = 0; success && i < ebsql->priv->n_summary_fields; i++) {
		SummaryField *field = &(ebsql->priv->summary_fields[i]);

		if (field->type != E_TYPE_CONTACT_ATTR_LIST)
			continue;

		stmt = generate_delete_stmt (field->aux_table, uids);
		success = ebsql_exec (ebsql, stmt, NULL, NULL, NULL, error);
		g_free (stmt);
	}

	/* Now delete the entry from the main contacts */
	if (success) {
		stmt = generate_delete_stmt (ebsql->priv->folderid, uids);
		success = ebsql_exec (ebsql, stmt, NULL, NULL, NULL, error);
		g_free (stmt);
	}

	if (success)
		success = ebsql_commit_transaction (ebsql, error);
	else
		/* The GError is already set. */
		ebsql_rollback_transaction (ebsql, NULL);

	EBSQL_UNLOCK_MUTEX (&ebsql->priv->lock);

	return success;
}

/**
 * e_book_sqlite_has_contact:
 * @ebsql: An #EBookSqlite
 * @uid: The uid of the contact to check for
 * @exists: (out): Return location to store whether the contact exists.
 * @error: (allow-none): A location to store any error that may have occurred.
 *
 * Checks if a contact bearing the UID indicated by @uid is stored in @ebsql.
 *
 * Returns: %TRUE on success, otherwise %FALSE is returned and @error is set appropriately.
 *
 * Since: 3.12
 **/
gboolean
e_book_sqlite_has_contact (EBookSqlite *ebsql,
                           const gchar *uid,
                           gboolean *exists,
                           GError **error)
{
	gboolean local_exists = FALSE;
	gboolean success;

	g_return_val_if_fail (E_IS_BOOK_SQLITE (ebsql), FALSE);
	g_return_val_if_fail (uid != NULL, FALSE);
	g_return_val_if_fail (exists != NULL, FALSE);

	EBSQL_LOCK_MUTEX (&ebsql->priv->lock);
	success = ebsql_exec_printf (
		ebsql,
		"SELECT uid FROM %Q WHERE uid = %Q",
		get_exists_cb, &local_exists, NULL, error,
		ebsql->priv->folderid, uid);
	EBSQL_UNLOCK_MUTEX (&ebsql->priv->lock);

	*exists = local_exists;

	return success;
}

/**
 * e_book_sqlite_get_contact:
 * @ebsql: An #EBookSqlite
 * @uid: The uid of the contact to fetch
 * @meta_contact: Whether an entire contact is desired, or only the metadata
 * @ret_contact: (out) (transfer full): Return location to store the fetched contact
 * @error: (allow-none): A location to store any error that may have occurred.
 *
 * Fetch the #EContact specified by @uid in @ebsql.
 *
 * If @meta_contact is specified, then a shallow #EContact will be created
 * holding only the %E_CONTACT_UID and %E_CONTACT_REV fields.
 *
 * Returns: %TRUE on success, otherwise %FALSE is returned and @error is set appropriately.
 *
 * Since: 3.12
 **/
gboolean
e_book_sqlite_get_contact (EBookSqlite *ebsql,
                           const gchar *uid,
                           gboolean meta_contact,
                           EContact **ret_contact,
                           GError **error)
{
	gboolean success = FALSE;
	gchar *vcard = NULL;

	g_return_val_if_fail (E_IS_BOOK_SQLITE (ebsql), FALSE);
	g_return_val_if_fail (uid != NULL, FALSE);
	g_return_val_if_fail (ret_contact != NULL && *ret_contact == NULL, FALSE);

	success = e_book_sqlite_get_vcard (
		ebsql, uid, meta_contact, &vcard, error);

	if (success && vcard) {
		*ret_contact = e_contact_new_from_vcard_with_uid (vcard, uid);
		g_free (vcard);
	}

	return success;
}

/**
 * ebsql_get_contact_unlocked:
 * @ebsql: An #EBookSqlite
 * @uid: The uid of the contact to fetch
 * @meta_contact: Whether an entire contact is desired, or only the metadata
 * @contact: (out) (transfer full): Return location to store the fetched contact
 * @error: (allow-none): A location to store any error that may have occurred.
 *
 * Fetch the #EContact specified by @uid in @ebsql without locking internal mutex.
 *
 * If @meta_contact is specified, then a shallow #EContact will be created
 * holding only the %E_CONTACT_UID and %E_CONTACT_REV fields.
 *
 * Returns: %TRUE on success, otherwise %FALSE is returned and @error is set appropriately.
 *
 * Since: 3.16
 **/
gboolean
ebsql_get_contact_unlocked (EBookSqlite *ebsql,
			    const gchar *uid,
			    gboolean meta_contact,
			    EContact **contact,
			    GError **error)
{
	gboolean success = FALSE;
	gchar *vcard = NULL;

	g_return_val_if_fail (E_IS_BOOK_SQLITE (ebsql), FALSE);
	g_return_val_if_fail (uid != NULL, FALSE);
	g_return_val_if_fail (contact != NULL && *contact == NULL, FALSE);

	success = ebsql_get_vcard_unlocked (ebsql,
					    uid,
					    meta_contact,
					    &vcard,
					    error);

	if (success && vcard) {
		*contact = e_contact_new_from_vcard_with_uid (vcard, uid);
		g_free (vcard);
	}

	return success;
}

/**
 * e_book_sqlite_get_vcard:
 * @ebsql: An #EBookSqlite
 * @uid: The uid of the contact to fetch
 * @meta_contact: Whether an entire contact is desired, or only the metadata
 * @ret_vcard: (out) (transfer full): Return location to store the fetched vcard string
 * @error: (allow-none): A location to store any error that may have occurred.
 *
 * Fetch a vcard string for @uid in @ebsql.
 *
 * If @meta_contact is specified, then a shallow vcard representation will be
 * created holding only the %E_CONTACT_UID and %E_CONTACT_REV fields.
 *
 * Returns: %TRUE on success, otherwise %FALSE is returned and @error is set appropriately.
 *
 * Since: 3.12
 **/
gboolean
e_book_sqlite_get_vcard (EBookSqlite *ebsql,
                         const gchar *uid,
                         gboolean meta_contact,
                         gchar **ret_vcard,
                         GError **error)
{
	gboolean success = FALSE;
	gchar *vcard = NULL;

	g_return_val_if_fail (E_IS_BOOK_SQLITE (ebsql), FALSE);
	g_return_val_if_fail (uid != NULL, FALSE);
	g_return_val_if_fail (ret_vcard != NULL && *ret_vcard == NULL, FALSE);

	EBSQL_LOCK_MUTEX (&ebsql->priv->lock);

	/* Try constructing contacts from only UID/REV first if that's requested */
	if (meta_contact) {
		GSList *vcards = NULL;

		success = ebsql_exec_printf (
			ebsql, "SELECT summary.uid, summary.Rev FROM %Q AS summary WHERE uid = %Q",
			collect_lean_results_cb, &vcards, NULL, error,
			ebsql->priv->folderid, uid);

		if (vcards) {
			EbSqlSearchData *search_data = (EbSqlSearchData *) vcards->data;

			vcard = search_data->vcard;
			search_data->vcard = NULL;

			g_slist_free_full (vcards, (GDestroyNotify) e_book_sqlite_search_data_free);
			vcards = NULL;
		}

	} else {
		success = ebsql_exec_printf (
			ebsql, "SELECT %s FROM %Q AS summary WHERE summary.uid = %Q",
			get_string_cb, &vcard, NULL, error,
			EBSQL_VCARD_FRAGMENT (ebsql), ebsql->priv->folderid, uid);
	}

	EBSQL_UNLOCK_MUTEX (&ebsql->priv->lock);

	*ret_vcard = vcard;

	if (success && !vcard) {
		EBSQL_SET_ERROR (
			error,
			E_BOOK_SQLITE_ERROR_CONTACT_NOT_FOUND,
			_("Contact “%s” not found"), uid);
		success = FALSE;
	}

	return success;
}

/**
 * ebsql_get_vcard_unlocked:
 * @ebsql: An #EBookSqlite
 * @uid: The uid of the contact to fetch
 * @meta_contact: Whether an entire contact is desired, or only the metadata
 * @ret_vcard: (out) (transfer full): Return location to store the fetched vcard string
 * @error: (allow-none): A location to store any error that may have occurred.
 *
 * Fetch a vcard string for @uid in @ebsql without locking internal mutex.
 *
 * If @meta_contact is specified, then a shallow vcard representation will be
 * created holding only the %E_CONTACT_UID and %E_CONTACT_REV fields.
 *
 * Returns: %TRUE on success, otherwise %FALSE is returned and @error is set appropriately.
 *
 * Since: 3.16
 **/
gboolean
ebsql_get_vcard_unlocked (EBookSqlite *ebsql,
                         const gchar *uid,
                         gboolean meta_contact,
                         gchar **ret_vcard,
                         GError **error)
{
	gboolean success = FALSE;
	gchar *vcard = NULL;

	g_return_val_if_fail (E_IS_BOOK_SQLITE (ebsql), FALSE);
	g_return_val_if_fail (uid != NULL, FALSE);
	g_return_val_if_fail (ret_vcard != NULL && *ret_vcard == NULL, FALSE);

	/* Try constructing contacts from only UID/REV first if that's requested */
	if (meta_contact) {
		GSList *vcards = NULL;

		success = ebsql_exec_printf (
			ebsql, "SELECT summary.uid, summary.Rev FROM %Q AS summary WHERE uid = %Q",
			collect_lean_results_cb, &vcards, NULL, error,
			ebsql->priv->folderid, uid);

		if (vcards) {
			EbSqlSearchData *search_data = (EbSqlSearchData *) vcards->data;

			vcard = search_data->vcard;
			search_data->vcard = NULL;

			g_slist_free_full (vcards, (GDestroyNotify) e_book_sqlite_search_data_free);
			vcards = NULL;
		}

       } else {
	       success = ebsql_exec_printf (
		       ebsql, "SELECT %s FROM %Q AS summary WHERE summary.uid = %Q",
		       get_string_cb, &vcard, NULL, error,
		       EBSQL_VCARD_FRAGMENT (ebsql), ebsql->priv->folderid, uid);
       }

	*ret_vcard = vcard;

	if (success && !vcard) {
		EBSQL_SET_ERROR (error,
				 E_BOOK_SQLITE_ERROR_CONTACT_NOT_FOUND,
				 _("Contact “%s” not found"), uid);
		success = FALSE;
	}

	return success;
}

/**
 * e_book_sqlite_set_contact_extra:
 * @ebsql: An #EBookSqlite
 * @uid: The uid of the contact to set the extra data for
 * @extra: (allow-none): The extra data to set
 * @error: (allow-none): A location to store any error that may have occurred.
 *
 * Sets or replaces the extra data associated with @uid.
 *
 * Returns: %TRUE on success, otherwise %FALSE is returned and @error is set appropriately.
 *
 * Since: 3.12
 **/
gboolean
e_book_sqlite_set_contact_extra (EBookSqlite *ebsql,
                                 const gchar *uid,
                                 const gchar *extra,
                                 GError **error)
{
	gboolean success;

	g_return_val_if_fail (E_IS_BOOK_SQLITE (ebsql), FALSE);
	g_return_val_if_fail (uid != NULL, FALSE);

	EBSQL_LOCK_MUTEX (&ebsql->priv->lock);
	success = ebsql_exec_printf (
		ebsql, "UPDATE %Q SET bdata = %Q WHERE uid = %Q",
		NULL, NULL, NULL, error,
		ebsql->priv->folderid, uid);
	EBSQL_UNLOCK_MUTEX (&ebsql->priv->lock);

	return success;
}

/**
 * e_book_sqlite_get_contact_extra:
 * @ebsql: An #EBookSqlite
 * @uid: The uid of the contact to fetch the extra data for
 * @ret_extra: (out) (transfer full): Return location to store the extra data
 * @error: (allow-none): A location to store any error that may have occurred.
 *
 * Fetches the extra data previously set for @uid, either with
 * e_book_sqlite_set_contact_extra() or when adding contacts.
 *
 * Returns: %TRUE on success, otherwise %FALSE is returned and @error is set appropriately.
 *
 * Since: 3.12
 **/
gboolean
e_book_sqlite_get_contact_extra (EBookSqlite *ebsql,
                                 const gchar *uid,
                                 gchar **ret_extra,
                                 GError **error)
{
	gboolean success;

	g_return_val_if_fail (E_IS_BOOK_SQLITE (ebsql), FALSE);
	g_return_val_if_fail (uid != NULL, FALSE);
	g_return_val_if_fail (ret_extra != NULL && *ret_extra == NULL, FALSE);

	EBSQL_LOCK_MUTEX (&ebsql->priv->lock);
	success = ebsql_exec_printf (
		ebsql, "SELECT bdata FROM %Q WHERE uid = %Q",
		get_string_cb, ret_extra, NULL, error,
		ebsql->priv->folderid, uid);
	EBSQL_UNLOCK_MUTEX (&ebsql->priv->lock);

	return success;
}

/**
 * ebsql_get_contact_extra_unlocked:
 * @ebsql: An #EBookSqlite
 * @uid: The uid of the contact to fetch the extra data for
 * @ret_extra: (out) (transfer full): Return location to store the extra data
 * @error: (allow-none): A location to store any error that may have occurred.
 *
 * Fetches the extra data previously set for @uid, either with
 * e_book_sqlite_set_contact_extra() or when adding contacts,
 * without locking internal mutex.
 *
 * Returns: %TRUE on success, otherwise %FALSE is returned and @error is set appropriately.
 *
 * Since: 3.16
 **/
gboolean
ebsql_get_contact_extra_unlocked (EBookSqlite *ebsql,
				  const gchar *uid,
				  gchar **ret_extra,
				  GError **error)
{
	gboolean success;

	g_return_val_if_fail (E_IS_BOOK_SQLITE (ebsql), FALSE);
	g_return_val_if_fail (uid != NULL, FALSE);
	g_return_val_if_fail (ret_extra != NULL && *ret_extra == NULL, FALSE);

	success = ebsql_exec_printf (
		ebsql, "SELECT bdata FROM %Q WHERE uid = %Q",
		get_string_cb, ret_extra, NULL, error,
		ebsql->priv->folderid, uid);

	return success;
}

/**
 * e_book_sqlite_search:
 * @ebsql: An #EBookSqlite
 * @sexp: (allow-none): search expression; use %NULL or an empty string to list all stored contacts.
 * @meta_contacts: Whether entire contacts are desired, or only the metadata
 * @ret_list: (out) (transfer full) (element-type EbSqlSearchData): Return location
 * to store a #GSList of #EbSqlSearchData structures
 * @cancellable: (allow-none): A #GCancellable
 * @error: (allow-none): A location to store any error that may have occurred.
 *
 * Searches @ebsql for contacts matching the search expression indicated by @sexp.
 *
 * When @sexp refers only to #EContactFields configured in the summary of @ebsql,
 * the search should always be quick, when searching for other #EContactFields
 * a fallback will be used, possibly invoking any #EbSqlVCardCallback which
 * may have been passed to e_book_sqlite_new_full().
 *
 * The returned @ret_list list should be freed with g_slist_free()
 * and all elements freed with e_book_sqlite_search_data_free().
 *
 * If @meta_contact is specified, then shallow vcard representations will be
 * created holding only the %E_CONTACT_UID and %E_CONTACT_REV fields.
 *
 * Returns: %TRUE on success, otherwise %FALSE is returned and @error is set appropriately.
 *
 * Since: 3.12
 **/
gboolean
e_book_sqlite_search (EBookSqlite *ebsql,
                      const gchar *sexp,
                      gboolean meta_contacts,
                      GSList **ret_list,
                      GCancellable *cancellable,
                      GError **error)
{
	gboolean success;

	g_return_val_if_fail (E_IS_BOOK_SQLITE (ebsql), FALSE);
	g_return_val_if_fail (ret_list != NULL && *ret_list == NULL, FALSE);

	EBSQL_LOCK_OR_RETURN (ebsql, cancellable, FALSE);
	success = ebsql_search_query (
		ebsql, sexp,
		meta_contacts ?
		SEARCH_UID_AND_REV : SEARCH_FULL,
		ret_list,
		cancellable,
		error);
	EBSQL_UNLOCK_MUTEX (&ebsql->priv->lock);

	return success;
}

/**
 * e_book_sqlite_search_uids:
 * @ebsql: An #EBookSqlite
 * @sexp: (allow-none): search expression; use %NULL or an empty string to get all stored contacts.
 * @ret_list: (out) (transfer full): Return location to store a #GSList of contact uids
 * @cancellable: (allow-none): A #GCancellable
 * @error: (allow-none): A location to store any error that may have occurred.
 *
 * Similar to e_book_sqlitedb_search(), but fetches only a list of contact UIDs.
 *
 * The returned @ret_list list should be freed with g_slist_free() and all
 * elements freed with g_free().
 *
 * Returns: %TRUE on success, otherwise %FALSE is returned and @error is set appropriately.
 *
 * Since: 3.12
 **/
gboolean
e_book_sqlite_search_uids (EBookSqlite *ebsql,
                           const gchar *sexp,
                           GSList **ret_list,
                           GCancellable *cancellable,
                           GError **error)
{
	gboolean success;

	g_return_val_if_fail (E_IS_BOOK_SQLITE (ebsql), FALSE);
	g_return_val_if_fail (ret_list != NULL && *ret_list == NULL, FALSE);

	EBSQL_LOCK_OR_RETURN (ebsql, cancellable, FALSE);
	success = ebsql_search_query (ebsql, sexp, SEARCH_UID, ret_list, cancellable, error);
	EBSQL_UNLOCK_MUTEX (&ebsql->priv->lock);

	return success;
}

/**
 * e_book_sqlite_get_key_value:
 * @ebsql: An #EBookSqlite
 * @key: The key to fetch a value for
 * @value: (out) (transfer full): A return location to store the value for @key
 * @error: (allow-none): A location to store any error that may have occurred.
 *
 * Fetches the value for @key and stores it in @value
 *
 * Returns: %TRUE on success, otherwise %FALSE is returned and @error is set appropriately.
 *
 * Since: 3.12
 **/
gboolean
e_book_sqlite_get_key_value (EBookSqlite *ebsql,
                             const gchar *key,
                             gchar **value,
                             GError **error)
{
	gboolean success;

	g_return_val_if_fail (E_IS_BOOK_SQLITE (ebsql), FALSE);
	g_return_val_if_fail (key != NULL, FALSE);
	g_return_val_if_fail (value != NULL && *value == NULL, FALSE);

	EBSQL_LOCK_MUTEX (&ebsql->priv->lock);
	success = ebsql_exec_printf (
		ebsql,
		"SELECT value FROM keys WHERE folder_id = %Q AND key = %Q",
		get_string_cb, value, NULL, error,
		ebsql->priv->folderid, key);
	EBSQL_UNLOCK_MUTEX (&ebsql->priv->lock);

	return success;
}

/**
 * e_book_sqlite_set_key_value:
 * @ebsql: An #EBookSqlite
 * @key: The key to fetch a value for
 * @value: The new value for @key
 * @error: (allow-none): A location to store any error that may have occurred.
 *
 * Sets the value for @key to be @value
 *
 * Returns: %TRUE on success, otherwise %FALSE is returned and @error is set appropriately.
 *
 * Since: 3.12
 **/
gboolean
e_book_sqlite_set_key_value (EBookSqlite *ebsql,
                             const gchar *key,
                             const gchar *value,
                             GError **error)
{
	gboolean success;

	g_return_val_if_fail (E_IS_BOOK_SQLITE (ebsql), FALSE);
	g_return_val_if_fail (key != NULL, FALSE);
	g_return_val_if_fail (value != NULL, FALSE);

	EBSQL_LOCK_MUTEX (&ebsql->priv->lock);
	success = ebsql_exec_printf (
		ebsql, "INSERT or REPLACE INTO keys (key, value, folder_id) values (%Q, %Q, %Q)",
		NULL, NULL, NULL, error,
		key, value, ebsql->priv->folderid);
	EBSQL_UNLOCK_MUTEX (&ebsql->priv->lock);

	return success;
}

/**
 * e_book_sqlite_get_key_value_int:
 * @ebsql: An #EBookSqlite
 * @key: The key to fetch a value for
 * @value: (out): A return location to store the value for @key
 * @error: (allow-none): A location to store any error that may have occurred.
 *
 * A convenience function to fetch the value of @key as an integer.
 *
 * Returns: %TRUE on success, otherwise %FALSE is returned and @error is set appropriately.
 *
 * Since: 3.12
 **/
gboolean
e_book_sqlite_get_key_value_int (EBookSqlite *ebsql,
                                 const gchar *key,
                                 gint *value,
                                 GError **error)
{
	gboolean success;
	gchar *str_value = NULL;

	g_return_val_if_fail (E_IS_BOOK_SQLITE (ebsql), FALSE);
	g_return_val_if_fail (key != NULL, FALSE);
	g_return_val_if_fail (value != NULL, FALSE);

	success = e_book_sqlite_get_key_value (ebsql, key, &str_value, error);

	if (success) {

		if (str_value)
			*value = g_ascii_strtoll (str_value, NULL, 10);
		else
			*value = 0;

		g_free (str_value);
	}

	return success;
}

/**
 * e_book_sqlite_set_key_value_int:
 * @ebsql: An #EBookSqlite
 * @key: The key to fetch a value for
 * @value: The new value for @key
 * @error: (allow-none): A location to store any error that may have occurred.
 *
 * A convenience function to set the value of @key as an integer.
 *
 * Returns: %TRUE on success, otherwise %FALSE is returned and @error is set appropriately.
 *
 * Since: 3.12
 **/
gboolean
e_book_sqlite_set_key_value_int (EBookSqlite *ebsql,
                                 const gchar *key,
                                 gint value,
                                 GError **error)
{
	gboolean success;
	gchar *str_value = NULL;

	g_return_val_if_fail (E_IS_BOOK_SQLITE (ebsql), FALSE);
	g_return_val_if_fail (key != NULL, FALSE);

	str_value = g_strdup_printf ("%d", value);
	success = e_book_sqlite_set_key_value (
		ebsql, key, str_value, error);
	g_free (str_value);

	return success;
}

/**
 * e_book_sqlite_search_data_free:
 * @data: An #EbSqlSearchData
 *
 * Frees an #EbSqlSearchData
 *
 * Since: 3.12
 **/
void
e_book_sqlite_search_data_free (EbSqlSearchData *data)
{
	if (data) {
		g_free (data->uid);
		g_free (data->vcard);
		g_free (data->extra);
		g_slice_free (EbSqlSearchData, data);
	}
}

/**
 * e_book_sqlite_set_locale:
 * @ebsql: An #EBookSqlite
 * @lc_collate: The new locale for the addressbook
 * @cancellable: (allow-none): A #GCancellable
 * @error: A location to store any error that may have occurred
 *
 * Relocalizes any locale specific data in the specified
 * new @lc_collate locale.
 *
 * The @lc_collate locale setting is stored and remembered on
 * subsequent accesses of the addressbook, changing the locale
 * will store the new locale and will modify sort keys and any
 * locale specific data in the addressbook.
 *
 * As a side effect, it's possible that changing the locale
 * will cause stored vcards to change. Notifications for
 * these changes can be caught with the #EbSqlVCardCallback
 * provided to e_book_sqlite_new_full().
 *
 * Returns: Whether the new locale was successfully set.
 *
 * Since: 3.12
 */
gboolean
e_book_sqlite_set_locale (EBookSqlite *ebsql,
                          const gchar *lc_collate,
                          GCancellable *cancellable,
                          GError **error)
{
	gboolean success;
	gchar *stored_lc_collate = NULL;

	g_return_val_if_fail (E_IS_BOOK_SQLITE (ebsql), FALSE);

	EBSQL_LOCK_OR_RETURN (ebsql, cancellable, FALSE);

	if (!ebsql_start_transaction (ebsql, EBSQL_LOCK_WRITE, cancellable, error)) {
		EBSQL_UNLOCK_MUTEX (&ebsql->priv->lock);
		return FALSE;
	}

	success = ebsql_set_locale_internal (ebsql, lc_collate, error);

	if (success)
		success = ebsql_exec_printf (
			ebsql, "SELECT lc_collate FROM folders WHERE folder_id = %Q",
			get_string_cb, &stored_lc_collate, NULL, error,
			ebsql->priv->folderid);

	if (success && g_strcmp0 (stored_lc_collate, lc_collate) != 0)
		success = ebsql_upgrade (ebsql, EBSQL_CHANGE_LOCALE_CHANGED, error);

	/* If for some reason we failed, then reset the collator to use the old locale */
	if (!success && stored_lc_collate && stored_lc_collate[0])
		ebsql_set_locale_internal (ebsql, stored_lc_collate, NULL);

	if (success)
		success = ebsql_commit_transaction (ebsql, error);
	else
		/* The GError is already set. */
		ebsql_rollback_transaction (ebsql, NULL);

	EBSQL_UNLOCK_MUTEX (&ebsql->priv->lock);

	g_free (stored_lc_collate);

	return success;
}

/**
 * e_book_sqlite_get_locale:
 * @ebsql: An #EBookSqlite
 * @locale_out: (out) (transfer full): The location to return the current locale
 * @error: A location to store any error that may have occurred
 *
 * Fetches the current locale setting for the address-book.
 *
 * Upon success, @lc_collate_out will hold the returned locale setting,
 * otherwise %FALSE will be returned and @error will be updated accordingly.
 *
 * Returns: Whether the locale was successfully fetched.
 *
 * Since: 3.12
 */
gboolean
e_book_sqlite_get_locale (EBookSqlite *ebsql,
                          gchar **locale_out,
                          GError **error)
{
	gboolean success;
	GError *local_error = NULL;

	g_return_val_if_fail (E_IS_BOOK_SQLITE (ebsql), FALSE);
	g_return_val_if_fail (locale_out != NULL && *locale_out == NULL, FALSE);

	EBSQL_LOCK_MUTEX (&ebsql->priv->lock);

	success = ebsql_exec_printf (
		ebsql, "SELECT lc_collate FROM folders WHERE folder_id = %Q",
		get_string_cb, locale_out, NULL, error,
		ebsql->priv->folderid);

	if (*locale_out == NULL) {

		/* This can't realistically happen, if it does we
		 * should warn about it in stdout */
		g_warning ("EBookSqlite has no active locale in the database");

		*locale_out = g_strdup (ebsql->priv->locale);
	}

	if (success && !ebsql_set_locale_internal (ebsql, *locale_out, &local_error)) {
		g_warning ("Error loading new locale: %s", local_error->message);
		g_clear_error (&local_error);
	}

	EBSQL_UNLOCK_MUTEX (&ebsql->priv->lock);

	return success;
}

/**
 * e_book_sqlite_cursor_new:
 * @ebsql: An #EBookSqlite
 * @sexp: search expression; use NULL or an empty string to get all stored contacts.
 * @sort_fields: (array length=n_sort_fields): An array of #EContactFields as sort keys in order of priority
 * @sort_types: (array length=n_sort_fields): An array of #EBookCursorSortTypes, one for each field in @sort_fields
 * @n_sort_fields: The number of fields to sort results by.
 * @error: A return location to store any error that might be reported.
 *
 * Creates a new #EbSqlCursor.
 *
 * The cursor should be freed with e_book_sqlite_cursor_free().
 *
 * Returns: (transfer full): A newly created #EbSqlCursor
 *
 * Since: 3.12
 */
EbSqlCursor *
e_book_sqlite_cursor_new (EBookSqlite *ebsql,
                          const gchar *sexp,
                          const EContactField *sort_fields,
                          const EBookCursorSortType *sort_types,
                          guint n_sort_fields,
                          GError **error)
{
	EbSqlCursor *cursor;
	gint i;

	g_return_val_if_fail (E_IS_BOOK_SQLITE (ebsql), NULL);

	/* We don't like '\0' sexps, prefer NULL */
	if (sexp && !sexp[0])
		sexp = NULL;

	EBSQL_LOCK_MUTEX (&ebsql->priv->lock);

	/* Need one sort key ... */
	if (n_sort_fields == 0) {
		EBSQL_SET_ERROR_LITERAL (
			error, E_BOOK_SQLITE_ERROR_INVALID_QUERY,
			_("At least one sort field must be specified to use an EbSqlCursor"));
		EBSQL_UNLOCK_MUTEX (&ebsql->priv->lock);
		return NULL;
	}

	/* We only support string fields to sort the cursor */
	for (i = 0; i < n_sort_fields; i++) {
		EBSQL_NOTE (
			CURSOR,
			g_printerr (
				"Building cursor to sort '%s' in '%s' order\n",
				e_contact_field_name (sort_fields[i]),
				sort_types[i] == E_BOOK_CURSOR_SORT_ASCENDING ?
				"ascending" : "descending"));

		if (e_contact_field_type (sort_fields[i]) != G_TYPE_STRING) {
			EBSQL_SET_ERROR_LITERAL (
				error, E_BOOK_SQLITE_ERROR_INVALID_QUERY,
				_("Cannot sort by a field that is not a string type"));
			EBSQL_UNLOCK_MUTEX (&ebsql->priv->lock);
			return NULL;
		}
	}

	/* Now we need to create the cursor instance before setting up the query
	 * (not really true, but more convenient that way).
	 */
	cursor = ebsql_cursor_new (ebsql, sexp, sort_fields, sort_types, n_sort_fields);

	/* Setup the cursor's query expression which might fail */
	if (!ebsql_cursor_setup_query (ebsql, cursor, sexp, error)) {
		ebsql_cursor_free (cursor);
		cursor = NULL;
	}

	EBSQL_UNLOCK_MUTEX (&ebsql->priv->lock);

	EBSQL_NOTE (
		CURSOR,
		g_printerr (
			"%s cursor with search expression '%s'\n",
			cursor ? "Successfully created" : "Failed to create",
			sexp));

	return cursor;
}

/**
 * e_book_sqlite_cursor_free:
 * @ebsql: An #EBookSqlite
 * @cursor: The #EbSqlCursor to free
 *
 * Frees @cursor.
 *
 * Since: 3.12
 */
void
e_book_sqlite_cursor_free (EBookSqlite *ebsql,
                           EbSqlCursor *cursor)
{
	g_return_if_fail (E_IS_BOOK_SQLITE (ebsql));

	ebsql_cursor_free (cursor);
}

typedef struct {
	GSList *results;
	gchar *alloc_vcard;
	const gchar *last_vcard;

	gboolean collect_results;
	gint n_results;
} CursorCollectData;

static gint
collect_results_for_cursor_cb (gpointer ref,
                               gint ncol,
                               gchar **cols,
                               gchar **names)
{
	CursorCollectData *data = ref;

	if (data->collect_results) {
		EbSqlSearchData *search_data;

		search_data = search_data_from_results (ncol, cols, names);

		data->results = g_slist_prepend (data->results, search_data);

		data->last_vcard = search_data->vcard;
	} else {
		g_free (data->alloc_vcard);
		data->alloc_vcard = g_strdup (cols[1]);

		data->last_vcard = data->alloc_vcard;
	}

	data->n_results++;

	return 0;
}

/**
 * e_book_sqlite_cursor_step:
 * @ebsql: An #EBookSqlite
 * @cursor: The #EbSqlCursor to use
 * @flags: The #EbSqlCursorStepFlags for this step
 * @origin: The #EbSqlCursorOrigin from whence to step
 * @count: A positive or negative amount of contacts to try and fetch
 * @results: (out) (allow-none) (element-type EbSqlSearchData) (transfer full):
 *   A return location to store the results, or %NULL if %EBSQL_CURSOR_STEP_FETCH is not specified in @flags.
 * @cancellable: (allow-none): A #GCancellable
 * @error: A return location to store any error that might be reported.
 *
 * Steps @cursor through it's sorted query by a maximum of @count contacts
 * starting from @origin.
 *
 * If @count is negative, then the cursor will move through the list in reverse.
 *
 * If @cursor reaches the beginning or end of the query results, then the
 * returned list might not contain the amount of desired contacts, or might
 * return no results if the cursor currently points to the last contact.
 * Reaching the end of the list is not considered an error condition. Attempts
 * to step beyond the end of the list after having reached the end of the list
 * will however trigger an %E_BOOK_SQLITE_ERROR_END_OF_LIST error.
 *
 * If %EBSQL_CURSOR_STEP_FETCH is specified in @flags, a pointer to
 * a %NULL #GSList pointer should be provided for the @results parameter.
 *
 * The result list will be stored to @results and should be freed with g_slist_free()
 * and all elements freed with e_book_sqlite_search_data_free().
 *
 * Returns: The number of contacts traversed if successful, otherwise -1 is
 * returned and @error is set.
 *
 * Since: 3.12
 */
gint
e_book_sqlite_cursor_step (EBookSqlite *ebsql,
                           EbSqlCursor *cursor,
                           EbSqlCursorStepFlags flags,
                           EbSqlCursorOrigin origin,
                           gint count,
                           GSList **results,
                           GCancellable *cancellable,
                           GError **error)
{
	CursorCollectData data = { NULL, NULL, NULL, FALSE, 0 };
	CursorState *state;
	GString *query;
	gboolean success;
	EbSqlCursorOrigin try_position;

	g_return_val_if_fail (E_IS_BOOK_SQLITE (ebsql), -1);
	g_return_val_if_fail (cursor != NULL, -1);
	g_return_val_if_fail ((flags & EBSQL_CURSOR_STEP_FETCH) == 0 ||
			      (results != NULL && *results == NULL), -1);

	/* Lock and check cancellable early */
	EBSQL_LOCK_OR_RETURN (ebsql, cancellable, -1);

	EBSQL_NOTE (
		CURSOR,
		g_printerr (
			"Cursor requested to step by %d with origin %s will move: %s will fetch: %s\n",
			count, ebsql_origin_str (origin),
			(flags & EBSQL_CURSOR_STEP_MOVE) ? "yes" : "no",
			(flags & EBSQL_CURSOR_STEP_FETCH) ? "yes" : "no"));

	/* Check if this step should result in an end of list error first */
	try_position = cursor->state.position;
	if (origin != EBSQL_CURSOR_ORIGIN_CURRENT)
		try_position = origin;

	/* Report errors for requests to run off the end of the list */
	if (try_position == EBSQL_CURSOR_ORIGIN_BEGIN && count < 0) {
		EBSQL_SET_ERROR_LITERAL (
			error, E_BOOK_SQLITE_ERROR_END_OF_LIST,
			_("Tried to step a cursor in reverse, "
			"but cursor is already at the beginning of the contact list"));

		EBSQL_UNLOCK_MUTEX (&ebsql->priv->lock);
		return -1;
	} else if (try_position == EBSQL_CURSOR_ORIGIN_END && count > 0) {
		EBSQL_SET_ERROR_LITERAL (
			error, E_BOOK_SQLITE_ERROR_END_OF_LIST,
			_("Tried to step a cursor forwards, "
			"but cursor is already at the end of the contact list"));

		EBSQL_UNLOCK_MUTEX (&ebsql->priv->lock);
		return -1;
	}

	/* Nothing to do, silently return */
	if (count == 0 && try_position == EBSQL_CURSOR_ORIGIN_CURRENT) {
		EBSQL_UNLOCK_MUTEX (&ebsql->priv->lock);
		return 0;
	}

	/* If we're not going to modify the position, just use
	 * a copy of the current cursor state.
	 */
	if ((flags & EBSQL_CURSOR_STEP_MOVE) != 0)
		state = &(cursor->state);
	else
		state = cursor_state_copy (cursor, &(cursor->state));

	/* Every query starts with the STATE_CURRENT position, first
	 * fix up the cursor state according to 'origin'
	 */
	switch (origin) {
	case EBSQL_CURSOR_ORIGIN_CURRENT:
		/* Do nothing, normal operation */
		break;

	case EBSQL_CURSOR_ORIGIN_BEGIN:
	case EBSQL_CURSOR_ORIGIN_END:

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
		if ((flags & EBSQL_CURSOR_STEP_MOVE) == 0)
			cursor_state_free (cursor, state);

		EBSQL_UNLOCK_MUTEX (&ebsql->priv->lock);
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

		constraints = ebsql_cursor_constraints (
			ebsql, cursor, state, count < 0, FALSE);

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
	data.collect_results = (flags & EBSQL_CURSOR_STEP_FETCH) != 0;

	/* Execute the query */
	success = ebsql_exec (
		ebsql, query->str,
		collect_results_for_cursor_cb, &data,
		cancellable, error);

	/* Lock was obtained above */
	EBSQL_UNLOCK_MUTEX (&ebsql->priv->lock);

	g_string_free (query, TRUE);

	/* If there was no error, update the internal cursor state */
	if (success) {

		if (data.n_results < ABS (count)) {

			/* We've reached the end, clear the current state */
			if (count < 0)
				cursor_state_clear (cursor, state, EBSQL_CURSOR_ORIGIN_BEGIN);
			else
				cursor_state_clear (cursor, state, EBSQL_CURSOR_ORIGIN_END);

		} else if (data.last_vcard) {

			/* Set the cursor state to the last result */
			cursor_state_set_from_vcard (ebsql, cursor, state, data.last_vcard);
		} else
			/* Should never get here */
			g_warn_if_reached ();

		/* Assign the results to return (if any) */
		if (results) {
			/* Correct the order of results at the last minute */
			*results = g_slist_reverse (data.results);
			data.results = NULL;
		}
	}

	/* Cleanup what was allocated by collect_results_for_cursor_cb() */
	if (data.results)
		g_slist_free_full (
			data.results,
			(GDestroyNotify) e_book_sqlite_search_data_free);
	g_free (data.alloc_vcard);

	/* Free the copy state if we were working with a copy */
	if ((flags & EBSQL_CURSOR_STEP_MOVE) == 0)
		cursor_state_free (cursor, state);

	if (success)
		return data.n_results;

	return -1;
}

/**
 * e_book_sqlite_cursor_set_target_alphabetic_index:
 * @ebsql: An #EBookSqlite
 * @cursor: The #EbSqlCursor to modify
 * @idx: The alphabetic index
 *
 * Sets the @cursor position to an
 * <link linkend="cursor-alphabet">Alphabetic Index</link>
 * into the alphabet active in @ebsql's locale.
 *
 * After setting the target to an alphabetic index, for example the
 * index for letter 'E', then further calls to e_book_sqlite_cursor_step()
 * will return results starting with the letter 'E' (or results starting
 * with the last result in 'D', if moving in a negative direction).
 *
 * The passed index must be a valid index in the active locale, knowledge
 * on the currently active alphabet index must be obtained using #ECollator
 * APIs.
 *
 * Use e_book_sqlite_ref_collator() to obtain the active collator for @ebsql.
 *
 * Since: 3.12
 */
void
e_book_sqlite_cursor_set_target_alphabetic_index (EBookSqlite *ebsql,
                                                  EbSqlCursor *cursor,
                                                  gint idx)
{
	gint n_labels = 0;

	g_return_if_fail (E_IS_BOOK_SQLITE (ebsql));
	g_return_if_fail (cursor != NULL);
	g_return_if_fail (idx >= 0);

	e_collator_get_index_labels (
		ebsql->priv->collator, &n_labels,
		NULL, NULL, NULL);
	g_return_if_fail (idx < n_labels);

	cursor_state_clear (cursor, &(cursor->state), EBSQL_CURSOR_ORIGIN_CURRENT);
	if (cursor->n_sort_fields > 0) {
		SummaryField *field;
		gchar *index_key;

		index_key = e_collator_generate_key_for_index (ebsql->priv->collator, idx);
		field = summary_field_get (ebsql, cursor->sort_fields[0]);

		if (field && (field->index & INDEX_FLAG (SORT_KEY)) != 0) {
			cursor->state.values[0] = index_key;
		} else {
			cursor->state.values[0] =
				ebsql_encode_vcard_sort_key (index_key);
			g_free (index_key);
		}
	}
}

/**
 * e_book_sqlite_cursor_set_sexp:
 * @ebsql: An #EBookSqlite
 * @cursor: The #EbSqlCursor
 * @sexp: The new query expression for @cursor
 * @error: A return location to store any error that might be reported.
 *
 * Modifies the current query expression for @cursor. This will not
 * modify @cursor's state, but will change the outcome of any further
 * calls to e_book_sqlite_cursor_calculate() or
 * e_book_sqlite_cursor_step().
 *
 * Returns: %TRUE if the expression was valid and accepted by @ebsql
 *
 * Since: 3.12
 */
gboolean
e_book_sqlite_cursor_set_sexp (EBookSqlite *ebsql,
                               EbSqlCursor *cursor,
                               const gchar *sexp,
                               GError **error)
{
	gboolean success;

	g_return_val_if_fail (E_IS_BOOK_SQLITE (ebsql), FALSE);
	g_return_val_if_fail (cursor != NULL, FALSE);

	/* We don't like '\0' sexps, prefer NULL */
	if (sexp && !sexp[0])
		sexp = NULL;

	EBSQL_LOCK_MUTEX (&ebsql->priv->lock);
	success = ebsql_cursor_setup_query (ebsql, cursor, sexp, error);
	EBSQL_UNLOCK_MUTEX (&ebsql->priv->lock);

	return success;
}

/**
 * e_book_sqlite_cursor_calculate:
 * @ebsql: An #EBookSqlite
 * @cursor: The #EbSqlCursor
 * @total: (out) (allow-none): A return location to store the total result set for this cursor
 * @position: (out) (allow-none): A return location to store the total results before the cursor value
 * @cancellable: (allow-none): A #GCancellable
 * @error: (allow-none): A return location to store any error that might be reported.
 *
 * Calculates the @total amount of results for the @cursor's query expression,
 * as well as the current @position of @cursor in the results. @position is
 * represented as the amount of results which lead up to the current value
 * of @cursor, if @cursor currently points to an exact contact, the position
 * also includes the cursor contact.
 *
 * Returns: Whether @total and @position were successfully calculated.
 *
 * Since: 3.12
 */
gboolean
e_book_sqlite_cursor_calculate (EBookSqlite *ebsql,
                                EbSqlCursor *cursor,
                                gint *total,
                                gint *position,
                                GCancellable *cancellable,
                                GError **error)
{
	gboolean success = TRUE;
	gint local_total = 0;

	g_return_val_if_fail (E_IS_BOOK_SQLITE (ebsql), FALSE);
	g_return_val_if_fail (cursor != NULL, FALSE);

	/* If we're in a clear cursor state, then the position is 0 */
	if (position && cursor->state.values[0] == NULL) {

		if (cursor->state.position == EBSQL_CURSOR_ORIGIN_BEGIN) {
			/* Mark the local pointer NULL, no need to calculate this anymore */
			*position = 0;
			position = NULL;
		} else if (cursor->state.position == EBSQL_CURSOR_ORIGIN_END) {

			/* Make sure that we look up the total so we can
			 * set the position to 'total + 1'
			 */
			if (!total)
				total = &local_total;
		}
	}

	/* Early return if there is nothing to do */
	if (!total && !position)
		return TRUE;

	EBSQL_LOCK_OR_RETURN (ebsql, cancellable, -1);

	/* Start a read transaction, it's important our two queries are atomic */
	if (!ebsql_start_transaction (ebsql, EBSQL_LOCK_READ, cancellable, error)) {
		EBSQL_UNLOCK_MUTEX (&ebsql->priv->lock);
		return FALSE;
	}

	if (total)
		success = cursor_count_total_locked (ebsql, cursor, total, error);

	if (success && position)
		success = cursor_count_position_locked (ebsql, cursor, position, error);

	if (success)
		success = ebsql_commit_transaction (ebsql, error);
	else
		/* The GError is already set. */
		ebsql_rollback_transaction (ebsql, NULL);

	EBSQL_UNLOCK_MUTEX (&ebsql->priv->lock);

	/* In the case we're at the end, we just set the position
	 * to be the total + 1
	 */
	if (success && position && total &&
	    cursor->state.position == EBSQL_CURSOR_ORIGIN_END)
		*position = *total + 1;

	return success;
}

/**
 * e_book_sqlite_cursor_compare_contact:
 * @ebsql: An #EBookSqlite
 * @cursor: The #EbSqlCursor
 * @contact: The #EContact to compare
 * @matches_sexp: (out) (allow-none): Whether the contact matches the cursor's search expression
 *
 * Compares @contact with @cursor and returns whether @contact is less than, equal to, or greater
 * than @cursor.
 *
 * Returns: A value that is less than, equal to, or greater than zero if @contact is found,
 * respectively, to be less than, to match, or be greater than the current value of @cursor.
 *
 * Since: 3.12
 */
gint
e_book_sqlite_cursor_compare_contact (EBookSqlite *ebsql,
                                      EbSqlCursor *cursor,
                                      EContact *contact,
                                      gboolean *matches_sexp)
{
	EBookSqlitePrivate *priv;
	gint i;
	gint comparison = 0;

	g_return_val_if_fail (E_IS_BOOK_SQLITE (ebsql), -1);
	g_return_val_if_fail (E_IS_CONTACT (contact), -1);
	g_return_val_if_fail (cursor != NULL, -1);

	priv = ebsql->priv;

	if (matches_sexp) {
		if (cursor->sexp == NULL)
			*matches_sexp = TRUE;
		else
			*matches_sexp =
				e_book_backend_sexp_match_contact (cursor->sexp, contact);
	}

	for (i = 0; i < cursor->n_sort_fields && comparison == 0; i++) {
		SummaryField *field;
		gchar *contact_key = NULL;
		const gchar *cursor_key = NULL;
		const gchar *field_value;
		gchar *freeme = NULL;

		field_value = (const gchar *) e_contact_get_const (contact, cursor->sort_fields[i]);
		if (field_value)
			contact_key = e_collator_generate_key (priv->collator, field_value, NULL);

		field = summary_field_get (ebsql, cursor->sort_fields[i]);

		if (field && (field->index & INDEX_FLAG (SORT_KEY)) != 0) {
			cursor_key = cursor->state.values[i];
		} else {

			if (cursor->state.values[i])
				freeme = ebsql_decode_vcard_sort_key (cursor->state.values[i]);

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

		uid = (const gchar *) e_contact_get_const (contact, E_CONTACT_UID);

		if (cursor->state.last_uid == NULL)
			comparison = 1;
		else if (uid == NULL)
			comparison = -1;
		else
			comparison = strcmp (uid, cursor->state.last_uid);
	}

	return comparison;
}
