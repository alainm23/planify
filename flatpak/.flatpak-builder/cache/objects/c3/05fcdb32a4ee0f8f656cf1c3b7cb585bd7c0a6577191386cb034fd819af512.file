/* A simple, extensible s-exp evaluation engine.
 *
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
 * Authors: Michael Zucchi <notzed@ximian.com>
 */

/*
 *   The following built-in s-exp's are supported:
 *
 *   list = (and list*)
 *      perform an intersection of a number of lists, and return that.
 *
 *   bool = (and bool*)
 *      perform a boolean AND of boolean values.
 *
 *   list = (or list*)
 *      perform a union of a number of lists, returning the new list.
 *
 *   bool = (or bool*)
 *      perform a boolean OR of boolean values.
 *
 *   gint = (+ int*)
 *      Add integers.
 *
 *   string = (+ string*)
 *      Concat strings.
 *
 *   time_t = (+ time_t*)
 *      Add time_t values.
 *
 *   gint = (- gint int*)
 *      Subtract integers from the first.
 *
 *   time_t = (- time_t*)
 *      Subtract time_t values from the first.
 *
 *   gint = (cast-int string|int|bool)
 *         Cast to an integer value.
 *
 *   string = (cast-string string|int|bool)
 *         Cast to an string value.
 *
 *   Comparison operators:
 *
 *   bool = (< gint gint)
 *   bool = (> gint gint)
 *   bool = (= gint gint)
 *
 *   bool = (< string string)
 *   bool = (> string string)
 *   bool = (= string string)
 *
 *   bool = (< time_t time_t)
 *   bool = (> time_t time_t)
 *   bool = (= time_t time_t)
 *      Perform a comparision of 2 integers, 2 string values, or 2 time values.
 *
 *   Function flow:
 *
 *   type = (if bool function)
 *   type = (if bool function function)
 *      Choose a flow path based on a boolean value
 *
 *   type = (begin  func func func)
 *         Execute a sequence.  The last function return is the return type.
 */

#include "evolution-data-server-config.h"

#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <string.h>

#include "camel-sexp.h"

#define p(x)			/* parse debug */
#define r(x)			/* run debug */
#define d(x)			/* general debug */

struct _CamelSExpPrivate {
	GScanner *scanner;	/* for parsing text version */
	CamelSExpTerm *tree;	/* root of expression tree */

	/* private stuff */
	jmp_buf failenv;
	gchar *error;
	GSList *operators;

	/* TODO: may also need a pool allocator for term strings,
	 *       so we dont lose them in error conditions? */
	CamelMemChunk *term_chunks;
	CamelMemChunk *result_chunks;
};

G_DEFINE_TYPE (CamelSExp, camel_sexp, G_TYPE_OBJECT)

static CamelSExpTerm * parse_list (CamelSExp *sexp, gint gotbrace);
static CamelSExpTerm * parse_value (CamelSExp *sexp);

#ifdef TESTER
static void parse_dump_term (CamelSExpTerm *term, gint depth);
#endif

typedef gboolean	(CamelSGeneratorFunc)	(gint argc,
						 CamelSExpResult **argv,
						 CamelSExpResult *result);
typedef gboolean	(CamelSOperatorFunc)	(gint argc,
						 CamelSExpResult **argv,
						 CamelSExpResult *result);

/* FIXME: constant _TIME_MAX used in different files, move it somewhere */
#define _TIME_MAX	((time_t) INT_MAX)	/* Max valid time_t	*/

static const GScannerConfig scanner_config =
{
	( (gchar *) " \t\r\n")		/* cset_skip_characters */,
	( (gchar *) G_CSET_a_2_z
	  "_+-<=>?"
	  G_CSET_A_2_Z)			/* cset_identifier_first */,
	( (gchar *) G_CSET_a_2_z
	  "_0123456789-<>?"
	  G_CSET_A_2_Z
	  G_CSET_LATINS
	  G_CSET_LATINC	)		/* cset_identifier_nth */,
	( (gchar *) ";\n" )		/* cpair_comment_single */,

	FALSE				/* case_sensitive */,

	TRUE				/* skip_comment_multi */,
	TRUE				/* skip_comment_single */,
	TRUE				/* scan_comment_multi */,
	TRUE				/* scan_identifier */,
	TRUE				/* scan_identifier_1char */,
	FALSE				/* scan_identifier_NULL */,
	TRUE				/* scan_symbols */,
	FALSE				/* scan_binary */,
	TRUE				/* scan_octal */,
	TRUE				/* scan_float */,
	TRUE				/* scan_hex */,
	FALSE				/* scan_hex_dollar */,
	TRUE				/* scan_string_sq */,
	TRUE				/* scan_string_dq */,
	TRUE				/* numbers_2_int */,
	FALSE				/* int_2_float */,
	FALSE				/* identifier_2_string */,
	TRUE				/* char_2_token */,
	FALSE				/* symbol_2_token */,
	FALSE				/* scope_0_fallback */,
};

/**
 * camel_sexp_fatal_error:
 * @sexp: a #CamelSExp
 * @why: a string format to use
 * @...: parameters for the format
 *
 * Sets an error from the given format and stops execution.
 * Int replaces previously set error, if any.
 *
 * Since: 3.4
 **/
void
camel_sexp_fatal_error (CamelSExp *sexp,
                        const gchar *why,
                        ...)
{
	va_list args;

	/* jumps back to the caller of sexp->priv->failenv,
	 * only to be called from inside a callback */

	if (sexp->priv->error)
		g_free (sexp->priv->error);

	va_start (args, why);
	sexp->priv->error = g_strdup_vprintf (why, args);
	va_end (args);

	longjmp (sexp->priv->failenv, 1);
}

/**
 * camel_sexp_error:
 * @sexp: a #CamelSExp
 *
 * Returns: (nullable): Set error string on the @sexp, or %NULL, when none is set
 *
 * Since: 3.4
 **/
const gchar *
camel_sexp_error (CamelSExp *sexp)
{
	return sexp->priv->error;
}

/**
 * camel_sexp_result_new: (skip)
 * @sexp: a #CamelSExp
 * @type: type of the result, one of #CamelSExpResultType
 *
 * Returns: (transfer full): A new #CamelSExpResult result structure, associated with @sexp.
 *    Free with camel_sexp_result_free(), when no longer needed.
 *
 * Since: 3.4
 **/
CamelSExpResult *
camel_sexp_result_new (CamelSExp *sexp,
                       gint type)
{
	CamelSExpResult *result;

	result = camel_memchunk_alloc0 (sexp->priv->result_chunks);
	result->type = type;
	result->occuring_start = 0;
	result->occuring_end = _TIME_MAX;
	result->time_generator = FALSE;

	return result;
}

/**
 * camel_sexp_result_free:
 * @sexp: a #CamelSExp
 * @result: (nullable): a #CamelSExpResult to free
 *
 * Frees the @result and its internal data. Does nothing,
 * when the @result is %NULL.
 *
 * Since: 3.4
 **/
void
camel_sexp_result_free (CamelSExp *sexp,
                        CamelSExpResult *result)
{
	if (result == NULL)
		return;

	switch (result->type) {
	case CAMEL_SEXP_RES_ARRAY_PTR:
		g_ptr_array_free (result->value.ptrarray, TRUE);
		break;
	case CAMEL_SEXP_RES_BOOL:
	case CAMEL_SEXP_RES_INT:
	case CAMEL_SEXP_RES_TIME:
		break;
	case CAMEL_SEXP_RES_STRING:
		g_free (result->value.string);
		break;
	case CAMEL_SEXP_RES_UNDEFINED:
		break;
	default:
		g_return_if_reached ();
	}
	camel_memchunk_free (sexp->priv->result_chunks, result);
}

/**
 * camel_sexp_resultv_free:
 * @sexp: a #CamelSExp
 * @argc: a count of the @argv
 * @argv: (array length=argc): an array of #CamelSExpResult to free
 *
 * Frees an array of results.
 *
 * Since: 3.4
 **/
void
camel_sexp_resultv_free (CamelSExp *sexp,
                         gint argc,
                         CamelSExpResult **argv)
{
	gint i;

	/* used in normal functions if they have to abort,
	 * and free their arguments */

	for (i = 0; i < argc; i++) {
		camel_sexp_result_free (sexp, argv[i]);
	}
}

/* implementations for the builtin functions */

/* we can only itereate a hashtable from a called function */
struct IterData {
	gint count;
	GPtrArray *uids;
};

/* ok, store any values that are in all sets */
static void
htand (gchar *key,
       gint value,
       struct IterData *iter_data)
{
	if (value == iter_data->count) {
		g_ptr_array_add (iter_data->uids, key);
	}
}

/* or, store all unique values */
static void
htor (gchar *key,
      gint value,
      struct IterData *iter_data)
{
	g_ptr_array_add (iter_data->uids, key);
}

static CamelSExpResult *
term_eval_and (CamelSExp *sexp,
               gint argc,
               CamelSExpTerm **argv,
               gpointer data)
{
	CamelSExpResult *result, *r1;
	GHashTable *ht = g_hash_table_new (g_str_hash, g_str_equal);
	struct IterData lambdafoo;
	gint type=-1;
	gint bool = TRUE;
	gint i;
	const gchar *oper;

	r (printf ("( and\n"));

	result = camel_sexp_result_new (sexp, CAMEL_SEXP_RES_UNDEFINED);

	oper = "AND";
	sexp->priv->operators = g_slist_prepend (sexp->priv->operators, (gpointer) oper);

	for (i = 0; bool && i < argc; i++) {
		r1 = camel_sexp_term_eval (sexp, argv[i]);
		if (type == -1)
			type = r1->type;
		if (type != r1->type) {
			camel_sexp_result_free (sexp, result);
			camel_sexp_result_free (sexp, r1);
			g_hash_table_destroy (ht);
			camel_sexp_fatal_error (sexp, "Invalid types in AND");
		} else if (r1->type == CAMEL_SEXP_RES_ARRAY_PTR) {
			gchar **a1;
			gint l1, j;

			a1 = (gchar **) r1->value.ptrarray->pdata;
			l1 = r1->value.ptrarray->len;
			for (j = 0; j < l1; j++) {
				gpointer ptr;
				gint n;
				ptr = g_hash_table_lookup (ht, a1[j]);
				n = GPOINTER_TO_INT (ptr);
				g_hash_table_insert (ht, a1[j], GINT_TO_POINTER (n + 1));
			}
		} else if (r1->type == CAMEL_SEXP_RES_BOOL) {
			bool = bool && r1->value.boolean;
		}
		camel_sexp_result_free (sexp, r1);
	}

	if (type == CAMEL_SEXP_RES_ARRAY_PTR) {
		lambdafoo.count = argc;
		lambdafoo.uids = g_ptr_array_new ();
		g_hash_table_foreach (ht, (GHFunc) htand, &lambdafoo);
		result->type = CAMEL_SEXP_RES_ARRAY_PTR;
		result->value.ptrarray = lambdafoo.uids;
	} else if (type == CAMEL_SEXP_RES_BOOL) {
		result->type = CAMEL_SEXP_RES_BOOL;
		result->value.boolean = bool;
	}

	g_hash_table_destroy (ht);
	sexp->priv->operators = g_slist_remove (sexp->priv->operators, oper);

	return result;
}

static CamelSExpResult *
term_eval_or (CamelSExp *sexp,
              gint argc,
              CamelSExpTerm **argv,
              gpointer data)
{
	CamelSExpResult *result, *r1;
	GHashTable *ht = g_hash_table_new (g_str_hash, g_str_equal);
	struct IterData lambdafoo;
	gint type = -1;
	gint bool = FALSE;
	gint i;
	const gchar *oper;

	r (printf ("(or \n"));

	oper = "OR";
	sexp->priv->operators = g_slist_prepend (sexp->priv->operators, (gpointer) oper);

	result = camel_sexp_result_new (sexp, CAMEL_SEXP_RES_UNDEFINED);

	for (i = 0; !bool && i < argc; i++) {
		r1 = camel_sexp_term_eval (sexp, argv[i]);
		if (type == -1)
			type = r1->type;
		if (r1->type != type) {
			camel_sexp_result_free (sexp, result);
			camel_sexp_result_free (sexp, r1);
			g_hash_table_destroy (ht);
			camel_sexp_fatal_error (sexp, "Invalid types in OR");
		} else if (r1->type == CAMEL_SEXP_RES_ARRAY_PTR) {
			gchar **a1;
			gint l1, j;

			a1 = (gchar **) r1->value.ptrarray->pdata;
			l1 = r1->value.ptrarray->len;
			for (j = 0; j < l1; j++) {
				g_hash_table_insert (ht, a1[j], (gpointer) 1);
			}
		} else if (r1->type == CAMEL_SEXP_RES_BOOL) {
			bool |= r1->value.boolean;
		}
		camel_sexp_result_free (sexp, r1);
	}

	if (type == CAMEL_SEXP_RES_ARRAY_PTR) {
		lambdafoo.count = argc;
		lambdafoo.uids = g_ptr_array_new ();
		g_hash_table_foreach (ht, (GHFunc) htor, &lambdafoo);
		result->type = CAMEL_SEXP_RES_ARRAY_PTR;
		result->value.ptrarray = lambdafoo.uids;
	} else if (type == CAMEL_SEXP_RES_BOOL) {
		result->type = CAMEL_SEXP_RES_BOOL;
		result->value.boolean = bool;
	}
	g_hash_table_destroy (ht);

	sexp->priv->operators = g_slist_remove (sexp->priv->operators, oper);
	return result;
}

static CamelSExpResult *
term_eval_not (CamelSExp *sexp,
               gint argc,
               CamelSExpResult **argv,
               gpointer data)
{
	gint res = TRUE;
	CamelSExpResult *result;

	if (argc > 0) {
		if (argv[0]->type == CAMEL_SEXP_RES_BOOL
		    && argv[0]->value.boolean)
			res = FALSE;
	}
	result = camel_sexp_result_new (sexp, CAMEL_SEXP_RES_BOOL);
	result->value.boolean = res;

	return result;
}

/* this should support all arguments ...? */
static CamelSExpResult *
term_eval_lt (CamelSExp *sexp,
              gint argc,
              CamelSExpTerm **argv,
              gpointer data)
{
	CamelSExpResult *result, *r1, *r2;

	result = camel_sexp_result_new (sexp, CAMEL_SEXP_RES_UNDEFINED);

	if (argc == 2) {
		r1 = camel_sexp_term_eval (sexp, argv[0]);
		r2 = camel_sexp_term_eval (sexp, argv[1]);
		if (r1->type != r2->type) {
			camel_sexp_result_free (sexp, r1);
			camel_sexp_result_free (sexp, r2);
			camel_sexp_result_free (sexp, result);
			camel_sexp_fatal_error (sexp, "Incompatible types in compare <");
		} else if (r1->type == CAMEL_SEXP_RES_INT) {
			result->type = CAMEL_SEXP_RES_BOOL;
			result->value.boolean = r1->value.number < r2->value.number;
		} else if (r1->type == CAMEL_SEXP_RES_TIME) {
			result->type = CAMEL_SEXP_RES_BOOL;
			result->value.boolean = r1->value.time < r2->value.time;
		} else if (r1->type == CAMEL_SEXP_RES_STRING) {
			result->type = CAMEL_SEXP_RES_BOOL;
			result->value.boolean = strcmp (r1->value.string, r2->value.string) < 0;
		}
		camel_sexp_result_free (sexp, r1);
		camel_sexp_result_free (sexp, r2);
	}
	return result;
}

/* this should support all arguments ...? */
static CamelSExpResult *
term_eval_gt (CamelSExp *sexp,
              gint argc,
              CamelSExpTerm **argv,
              gpointer data)
{
	CamelSExpResult *result, *r1, *r2;

	result = camel_sexp_result_new (sexp, CAMEL_SEXP_RES_UNDEFINED);

	if (argc == 2) {
		r1 = camel_sexp_term_eval (sexp, argv[0]);
		r2 = camel_sexp_term_eval (sexp, argv[1]);
		if (r1->type != r2->type) {
			camel_sexp_result_free (sexp, r1);
			camel_sexp_result_free (sexp, r2);
			camel_sexp_result_free (sexp, result);
			camel_sexp_fatal_error (sexp, "Incompatible types in compare >");
		} else if (r1->type == CAMEL_SEXP_RES_INT) {
			result->type = CAMEL_SEXP_RES_BOOL;
			result->value.boolean = r1->value.number > r2->value.number;
		} else if (r1->type == CAMEL_SEXP_RES_TIME) {
			result->type = CAMEL_SEXP_RES_BOOL;
			result->value.boolean = r1->value.time > r2->value.time;
		} else if (r1->type == CAMEL_SEXP_RES_STRING) {
			result->type = CAMEL_SEXP_RES_BOOL;
			result->value.boolean = strcmp (r1->value.string, r2->value.string) > 0;
		}
		camel_sexp_result_free (sexp, r1);
		camel_sexp_result_free (sexp, r2);
	}
	return result;
}

/* this should support all arguments ...? */
static CamelSExpResult *
term_eval_eq (CamelSExp *sexp,
              gint argc,
              CamelSExpTerm **argv,
              gpointer data)
{
	CamelSExpResult *result, *r1, *r2;

	result = camel_sexp_result_new (sexp, CAMEL_SEXP_RES_BOOL);

	if (argc == 2) {
		r1 = camel_sexp_term_eval (sexp, argv[0]);
		r2 = camel_sexp_term_eval (sexp, argv[1]);
		if (r1->type != r2->type) {
			result->value.boolean = FALSE;
		} else if (r1->type == CAMEL_SEXP_RES_INT) {
			result->value.boolean = r1->value.number == r2->value.number;
		} else if (r1->type == CAMEL_SEXP_RES_BOOL) {
			result->value.boolean = r1->value.boolean == r2->value.boolean;
		} else if (r1->type == CAMEL_SEXP_RES_TIME) {
			result->value.boolean = r1->value.time == r2->value.time;
		} else if (r1->type == CAMEL_SEXP_RES_STRING) {
			result->value.boolean = strcmp (r1->value.string, r2->value.string) == 0;
		}
		camel_sexp_result_free (sexp, r1);
		camel_sexp_result_free (sexp, r2);
	}
	return result;
}

static CamelSExpResult *
term_eval_plus (CamelSExp *sexp,
                gint argc,
                CamelSExpResult **argv,
                gpointer data)
{
	CamelSExpResult *result = NULL;
	gint type;
	gint i;

	if (argc > 0) {
		type = argv[0]->type;
		switch (type) {
		case CAMEL_SEXP_RES_INT: {
			gint total = argv[0]->value.number;
			for (i = 1; i < argc && argv[i]->type == CAMEL_SEXP_RES_INT; i++) {
				total += argv[i]->value.number;
			}
			if (i < argc) {
				camel_sexp_resultv_free (sexp, argc, argv);
				camel_sexp_fatal_error (sexp, "Invalid types in (+ ints)");
			}
			result = camel_sexp_result_new (sexp, CAMEL_SEXP_RES_INT);
			result->value.number = total;
			break; }
		case CAMEL_SEXP_RES_STRING: {
			GString *string = g_string_new (argv[0]->value.string);
			for (i = 1; i < argc && argv[i]->type == CAMEL_SEXP_RES_STRING; i++) {
				g_string_append (string, argv[i]->value.string);
			}
			if (i < argc) {
				camel_sexp_resultv_free (sexp, argc, argv);
				camel_sexp_fatal_error (sexp, "Invalid types in (+ strings)");
			}
			result = camel_sexp_result_new (sexp, CAMEL_SEXP_RES_STRING);
			result->value.string = string->str;
			g_string_free (string, FALSE);
			break; }
		case CAMEL_SEXP_RES_TIME: {
			time_t total;

			total = argv[0]->value.time;

			for (i = 1; i < argc && argv[i]->type == CAMEL_SEXP_RES_TIME; i++)
				total += argv[i]->value.time;

			if (i < argc) {
				camel_sexp_resultv_free (sexp, argc, argv);
				camel_sexp_fatal_error (sexp, "Invalid types in (+ time_t)");
			}

			result = camel_sexp_result_new (sexp, CAMEL_SEXP_RES_TIME);
			result->value.time = total;
			break; }
		}
	}

	if (result == NULL) {
		result = camel_sexp_result_new (sexp, CAMEL_SEXP_RES_INT);
		result->value.number = 0;
	}

	return result;
}

static CamelSExpResult *
term_eval_sub (CamelSExp *sexp,
               gint argc,
               CamelSExpResult **argv,
               gpointer data)
{
	CamelSExpResult *result = NULL;
	gint type;
	gint i;

	if (argc > 0) {
		type = argv[0]->type;
		switch (type) {
		case CAMEL_SEXP_RES_INT: {
			gint total = argv[0]->value.number;
			for (i = 1; i < argc && argv[i]->type == CAMEL_SEXP_RES_INT; i++) {
				total -= argv[i]->value.number;
			}
			if (i < argc) {
				camel_sexp_resultv_free (sexp, argc, argv);
				camel_sexp_fatal_error (sexp, "Invalid types in -");
			}
			result = camel_sexp_result_new (sexp, CAMEL_SEXP_RES_INT);
			result->value.number = total;
			break; }
		case CAMEL_SEXP_RES_TIME: {
			time_t total;

			total = argv[0]->value.time;

			for (i = 1; i < argc && argv[i]->type == CAMEL_SEXP_RES_TIME; i++)
				total -= argv[i]->value.time;

			if (i < argc) {
				camel_sexp_resultv_free (sexp, argc, argv);
				camel_sexp_fatal_error (sexp, "Invalid types in (- time_t)");
			}

			result = camel_sexp_result_new (sexp, CAMEL_SEXP_RES_TIME);
			result->value.time = total;
			break; }
		}
	}

	if (result == NULL) {
		result = camel_sexp_result_new (sexp, CAMEL_SEXP_RES_INT);
		result->value.number = 0;
	}
	return result;
}

/* cast to gint */
static CamelSExpResult *
term_eval_castint (CamelSExp *sexp,
                   gint argc,
                   CamelSExpResult **argv,
                   gpointer data)
{
	CamelSExpResult *result;

	if (argc != 1)
		camel_sexp_fatal_error (sexp, "Incorrect argument count to (gint )");

	result = camel_sexp_result_new (sexp, CAMEL_SEXP_RES_INT);
	switch (argv[0]->type) {
	case CAMEL_SEXP_RES_INT:
		result->value.number = argv[0]->value.number;
		break;
	case CAMEL_SEXP_RES_BOOL:
		result->value.number = argv[0]->value.boolean != 0;
		break;
	case CAMEL_SEXP_RES_STRING:
		result->value.number = strtoul (argv[0]->value.string, NULL, 10);
		break;
	default:
		camel_sexp_result_free (sexp, result);
		camel_sexp_fatal_error (sexp, "Invalid type in (cast-int )");
	}

	return result;
}

/* cast to string */
static CamelSExpResult *
term_eval_caststring (CamelSExp *sexp,
                      gint argc,
                      CamelSExpResult **argv,
                      gpointer data)
{
	CamelSExpResult *result;

	if (argc != 1)
		camel_sexp_fatal_error (sexp, "Incorrect argument count to (cast-string )");

	result = camel_sexp_result_new (sexp, CAMEL_SEXP_RES_STRING);
	switch (argv[0]->type) {
	case CAMEL_SEXP_RES_INT:
		result->value.string = g_strdup_printf ("%d", argv[0]->value.number);
		break;
	case CAMEL_SEXP_RES_BOOL:
		result->value.string = g_strdup_printf ("%d", argv[0]->value.boolean != 0);
		break;
	case CAMEL_SEXP_RES_STRING:
		result->value.string = g_strdup (argv[0]->value.string);
		break;
	default:
		camel_sexp_result_free (sexp, result);
		camel_sexp_fatal_error (sexp, "Invalid type in (gint )");
	}

	return result;
}

/* implements 'if' function */
static CamelSExpResult *
term_eval_if (CamelSExp *sexp,
              gint argc,
              CamelSExpTerm **argv,
              gpointer data)
{
	CamelSExpResult *result;
	gint doit;

	if (argc >=2 && argc <= 3) {
		result = camel_sexp_term_eval (sexp, argv[0]);
		doit = (result->type == CAMEL_SEXP_RES_BOOL && result->value.boolean);
		camel_sexp_result_free (sexp, result);
		if (doit) {
			return camel_sexp_term_eval (sexp, argv[1]);
		} else if (argc > 2) {
			return camel_sexp_term_eval (sexp, argv[2]);
		}
	}
	return camel_sexp_result_new (sexp, CAMEL_SEXP_RES_UNDEFINED);
}

/* implements 'begin' statement */
static CamelSExpResult *
term_eval_begin (CamelSExp *sexp,
                 gint argc,
                 CamelSExpTerm **argv,
                 gpointer data)
{
	CamelSExpResult *result = NULL;
	gint i;

	for (i = 0; i < argc; i++) {
		if (result != NULL)
			camel_sexp_result_free (sexp, result);
		result = camel_sexp_term_eval (sexp, argv[i]);
	}
	if (result != NULL)
		return result;
	else
		return camel_sexp_result_new (sexp, CAMEL_SEXP_RES_UNDEFINED);
}

/**
 * camel_sexp_term_eval: (skip)
 * @sexp: a #CamelSExp
 * @term: a #CamelSExpTerm to evaluate
 *
 * Evaluates a part of the expression.
 *
 * Returns: (transfer full): a newly allocated result of the evaluation. Free
 *    the returned pointer with camel_sexp_result_free(), when no longer needed.
 *
 * Since: 3.4
 **/
CamelSExpResult *
camel_sexp_term_eval (CamelSExp *sexp,
                      CamelSExpTerm *term)
{
	CamelSExpResult *result = NULL;
	gint i, argc;
	CamelSExpResult **argv;

	/* this must only be called from inside term evaluation callbacks! */

	g_return_val_if_fail (term != NULL, NULL);

	r (printf ("eval term :\n"));
	r (parse_dump_term (term, 0));

	switch (term->type) {
	case CAMEL_SEXP_TERM_STRING:
		r (printf (" (string \"%s\")\n", term->value.string));
		result = camel_sexp_result_new (sexp, CAMEL_SEXP_RES_STRING);
		/* erk, this shoul;dn't need to strdup this ... */
		result->value.string = g_strdup (term->value.string);
		break;
	case CAMEL_SEXP_TERM_INT:
		r (printf (" (gint %d)\n", term->value.number));
		result = camel_sexp_result_new (sexp, CAMEL_SEXP_RES_INT);
		result->value.number = term->value.number;
		break;
	case CAMEL_SEXP_TERM_BOOL:
		r (printf (" (gint %d)\n", term->value.number));
		result = camel_sexp_result_new (sexp, CAMEL_SEXP_RES_BOOL);
		result->value.boolean = term->value.boolean;
		break;
	case CAMEL_SEXP_TERM_TIME:
		r (printf (" (time_t %ld)\n", term->value.time));
		result = camel_sexp_result_new (sexp, CAMEL_SEXP_RES_TIME);
		result->value.time = term->value.time;
		break;
	case CAMEL_SEXP_TERM_IFUNC:
		if (term->value.func.sym && term->value.func.sym->f.ifunc)
			result = term->value.func.sym->f.ifunc (sexp, term->value.func.termcount, term->value.func.terms, term->value.func.sym->data);
		break;
	case CAMEL_SEXP_TERM_FUNC:
		/* first evaluate all arguments to result types */
		argc = term->value.func.termcount;
		argv = g_alloca (sizeof (argv[0]) * argc);
		for (i = 0; i < argc; i++) {
			argv[i] = camel_sexp_term_eval (sexp, term->value.func.terms[i]);
		}
		/* call the function */
		if (term->value.func.sym->f.func)
			result = term->value.func.sym->f.func (sexp, argc, argv, term->value.func.sym->data);

		camel_sexp_resultv_free (sexp, argc, argv);
		break;
	default:
		camel_sexp_fatal_error (sexp, "Unknown type in parse tree: %d", term->type);
	}

	if (result == NULL)
		result = camel_sexp_result_new (sexp, CAMEL_SEXP_RES_UNDEFINED);

	return result;
}

#ifdef TESTER
static void
eval_dump_result (CamelSExpResult *result,
                  gint depth)
{
	gint i;

	if (result == NULL) {
		printf ("null result???\n");
		return;
	}

	for (i = 0; i < depth; i++)
		printf ("   ");

	switch (result->type) {
	case CAMEL_SEXP_RES_ARRAY_PTR:
		printf ("array pointers\n");
		break;
	case CAMEL_SEXP_RES_INT:
		printf ("int: %d\n", result->value.number);
		break;
	case CAMEL_SEXP_RES_STRING:
		printf ("string: '%s'\n", result->value.string);
		break;
	case CAMEL_SEXP_RES_BOOL:
		printf ("bool: %c\n", result->value.boolean ? 't':'f');
		break;
	case CAMEL_SEXP_RES_TIME:
		printf ("time_t: %ld\n", (glong) result->value.time);
		break;
	case CAMEL_SEXP_RES_UNDEFINED:
		printf (" <undefined>\n");
		break;
	}
	printf ("\n");
}
#endif

#ifdef TESTER
static void
parse_dump_term (CamelSExpTerm *term,
                 gint depth)
{
	gint i;

	if (t == NULL) {
		printf ("null term??\n");
		return;
	}

	for (i = 0; i < depth; i++)
		printf ("   ");

	switch (term->type) {
	case CAMEL_SEXP_TERM_STRING:
		printf (" \"%s\"", term->value.string);
		break;
	case CAMEL_SEXP_TERM_INT:
		printf (" %d", term->value.number);
		break;
	case CAMEL_SEXP_TERM_BOOL:
		printf (" #%c", term->value.boolean ? 't':'f');
		break;
	case CAMEL_SEXP_TERM_TIME:
		printf (" %ld", (glong) term->value.time);
		break;
	case CAMEL_SEXP_TERM_IFUNC:
	case CAMEL_SEXP_TERM_FUNC:
		printf (" (function %s\n", term->value.func.sym->name);
		/*printf(" [%d] ", term->value.func.termcount);*/
		for (i = 0; i < term->value.func.termcount; i++) {
			parse_dump_term (term->value.func.terms[i], depth + 1);
		}
		for (i = 0; i < depth; i++)
			printf ("   ");
		printf (" )");
		break;
	case CAMEL_SEXP_TERM_VAR:
		printf (" (variable %s )\n", term->value.var->name);
		break;
	default:
		printf ("unknown type: %d\n", term->type);
	}

	printf ("\n");
}
#endif

static const gchar *time_functions[] = {
	"time-now",
	"make-time",
	"time-add-day",
	"time-day-begin",
	"time-day-end"
};

static gboolean
occur_in_time_range_generator (gint argc,
                               CamelSExpResult **argv,
                               CamelSExpResult *result)
{
	g_return_val_if_fail (result != NULL, FALSE);
	g_return_val_if_fail (argc == 2 || argc == 3, FALSE);

	if ((argv[0]->type != CAMEL_SEXP_RES_TIME) || (argv[1]->type != CAMEL_SEXP_RES_TIME))
		return FALSE;

	result->occuring_start = argv[0]->value.time;
	result->occuring_end = argv[1]->value.time;

	return TRUE;
}

static gboolean
binary_generator (gint argc,
                  CamelSExpResult **argv,
                  CamelSExpResult *result)
{
	g_return_val_if_fail (result != NULL, FALSE);
	g_return_val_if_fail (argc == 2, FALSE);

	if ((argv[0]->type != CAMEL_SEXP_RES_TIME) || (argv[1]->type != CAMEL_SEXP_RES_TIME))
		return FALSE;

	result->occuring_start = argv[0]->value.time;
	result->occuring_end = argv[1]->value.time;

	return TRUE;
}

static gboolean
unary_generator (gint argc,
                 CamelSExpResult **argv,
                 CamelSExpResult *result)
{
	/* unary generator with end time */
	g_return_val_if_fail (result != NULL, FALSE);
	g_return_val_if_fail (argc == 1, FALSE);

	if (argv[0]->type != CAMEL_SEXP_RES_TIME)
		return FALSE;

	result->occuring_start = 0;
	result->occuring_end = argv[0]->value.time;

	return TRUE;
}

static const struct {
	const gchar *name;
	CamelSGeneratorFunc *func;
} generators[] = {
	{"occur-in-time-range?", occur_in_time_range_generator},
	{"due-in-time-range?", binary_generator},
	{"has-alarms-in-range?", binary_generator},
	{"completed-before?", unary_generator},
};

static gboolean
or_operator (gint argc,
             CamelSExpResult **argv,
             CamelSExpResult *result)
{
	gint ii;

	/*
	 * A          B           A or B
	 * ----       ----        ------
	 * norm (0)   norm (0)    norm (0)
	 * gen (1)    norm (0)    norm (0)
	 * norm (0)   gen (1)     norm (0)
	 * gen (1)    gen (1)     gen*(1)
	 */

	g_return_val_if_fail (result != NULL, FALSE);
	g_return_val_if_fail (argc > 0, FALSE);

	result->time_generator = TRUE;
	for (ii = 0; ii < argc && result->time_generator; ii++) {
		result->time_generator = argv[ii]->time_generator;
	}

	if (result->time_generator) {
		result->occuring_start = argv[0]->occuring_start;
		result->occuring_end = argv[0]->occuring_end;

		for (ii = 1; ii < argc; ii++) {
			result->occuring_start = MIN (result->occuring_start, argv[ii]->occuring_start);
			result->occuring_end = MAX (result->occuring_end, argv[ii]->occuring_end);
		}
	}

	return TRUE;
}

static gboolean
and_operator (gint argc,
              CamelSExpResult **argv,
              CamelSExpResult *result)
{
	gint ii;

	/*
	 * A           B          A and B
	 * ----        ----       ------- -
	 * norm (0)     norm (0)    norm (0)
	 * gen (1)      norm (0)    gen (1)
	 * norm (0)     gen (1)     gen (1)
	 * gen (1)      gen (1)     gen (1)
	 * */

	g_return_val_if_fail (result != NULL, FALSE);
	g_return_val_if_fail (argc > 0, FALSE);

	result->time_generator = FALSE;
	for (ii = 0; ii < argc && !result->time_generator; ii++) {
		result->time_generator = argv[ii]->time_generator;
	}

	if (result->time_generator) {
		result->occuring_start = argv[0]->occuring_start;
		result->occuring_end = argv[0]->occuring_end;

		for (ii = 1; ii < argc; ii++) {
			result->occuring_start = MAX (result->occuring_start, argv[ii]->occuring_start);
			result->occuring_end = MIN (result->occuring_end, argv[ii]->occuring_end);
		}
	}

	return TRUE;
}

static const struct {
	const gchar *name;
	CamelSOperatorFunc *func;
} operators[] = {
	{"or", or_operator},
	{"and", and_operator}
};

static CamelSOperatorFunc *
get_operator_function (const gchar *fname)
{
	gint i;

	g_return_val_if_fail (fname != NULL, NULL);

	for (i = 0; i < sizeof (operators) / sizeof (operators[0]); i++)
		if (strcmp (operators[i].name, fname) == 0)
			return operators[i].func;

	return NULL;
}

static inline gboolean
is_time_function (const gchar *fname)
{
	gint i;

	g_return_val_if_fail (fname != NULL, FALSE);

	for (i = 0; i < sizeof (time_functions) / sizeof (time_functions[0]); i++)
		if (strcmp (time_functions[i], fname) == 0)
			return TRUE;

	return FALSE;
}

static CamelSGeneratorFunc *
get_generator_function (const gchar *fname)
{
	gint i;

	g_return_val_if_fail (fname != NULL, NULL);

	for (i = 0; i < sizeof (generators) / sizeof (generators[0]); i++)
		if (strcmp (generators[i].name, fname) == 0)
			return generators[i].func;

	return NULL;
}

/* this must only be called from inside term evaluation callbacks! */
static CamelSExpResult *
camel_sexp_term_evaluate_occur_times (CamelSExp *sexp,
                                      CamelSExpTerm *term,
                                      time_t *start,
                                      time_t *end)
{
	CamelSExpResult *result = NULL;
	gint i, argc;
	CamelSExpResult **argv;
	gboolean ok = TRUE;

	g_return_val_if_fail (term != NULL, NULL);
	g_return_val_if_fail (start != NULL, NULL);
	g_return_val_if_fail (end != NULL, NULL);

	/*
	printf ("eval term :\n");
	parse_dump_term (t, 0);
	*/

	switch (term->type) {
	case CAMEL_SEXP_TERM_STRING:
		r (printf (" (string \"%s\")\n", term->value.string));
		result = camel_sexp_result_new (sexp, CAMEL_SEXP_RES_STRING);
		result->value.string = g_strdup (term->value.string);
		break;
	case CAMEL_SEXP_TERM_IFUNC:
	case CAMEL_SEXP_TERM_FUNC:
	{
		CamelSGeneratorFunc *generator = NULL;
		CamelSOperatorFunc *operator = NULL;

		r (printf (" (function \"%s\"\n", term->value.func.sym->name));

		result = camel_sexp_result_new (sexp, CAMEL_SEXP_RES_UNDEFINED);
		argc = term->value.func.termcount;
		argv = g_alloca (sizeof (argv[0]) * argc);

		for (i = 0; i < argc; i++) {
			argv[i] = camel_sexp_term_evaluate_occur_times (
				sexp, term->value.func.terms[i], start, end);
		}

		if (is_time_function (term->value.func.sym->name)) {
			/* evaluate time */
			if (term->value.func.sym->f.func)
				result = term->value.func.sym->f.func (sexp, argc, argv, term->value.func.sym->data);
		} else if ((generator = get_generator_function (term->value.func.sym->name)) != NULL) {
			/* evaluate generator function */
			result->time_generator = TRUE;
			ok = generator (argc, argv, result);
		} else if ((operator = get_operator_function (term->value.func.sym->name)) != NULL)
			/* evaluate operator function */
			ok = operator (argc, argv, result);
		else {
			/* normal function: we need to scan all objects */
			result->time_generator = FALSE;
		}

		camel_sexp_resultv_free (sexp, argc, argv);
		break;
	}
	case CAMEL_SEXP_TERM_INT:
	case CAMEL_SEXP_TERM_BOOL:
	case CAMEL_SEXP_TERM_TIME:
		break;
	default:
		ok = FALSE;
		break;
	}

	if (!ok)
		camel_sexp_fatal_error (sexp, "Error in parse tree");

	if (result == NULL)
		result = camel_sexp_result_new (sexp, CAMEL_SEXP_RES_UNDEFINED);

	return result;
}

/*
  PARSER
*/

static CamelSExpTerm *
parse_term_new (CamelSExp *sexp,
                gint type)
{
	CamelSExpTerm *term;

	term = camel_memchunk_alloc0 (sexp->priv->term_chunks);
	term->type = type;

	return term;
}

static void
parse_term_free (CamelSExp *sexp,
                 CamelSExpTerm *term)
{
	gint i;

	if (term == NULL) {
		return;
	}

	switch (term->type) {
	case CAMEL_SEXP_TERM_INT:
	case CAMEL_SEXP_TERM_BOOL:
	case CAMEL_SEXP_TERM_TIME:
	case CAMEL_SEXP_TERM_VAR:
		break;

	case CAMEL_SEXP_TERM_STRING:
		g_free (term->value.string);
		break;

	case CAMEL_SEXP_TERM_FUNC:
	case CAMEL_SEXP_TERM_IFUNC:
		for (i = 0; i < term->value.func.termcount; i++) {
			parse_term_free (sexp, term->value.func.terms[i]);
		}
		g_free (term->value.func.terms);
		break;

	default:
		printf ("parse_term_free: unknown type: %d\n", term->type);
	}
	camel_memchunk_free (sexp->priv->term_chunks, term);
}

static CamelSExpTerm **
parse_values (CamelSExp *sexp,
              gint *len)
{
	gint token;
	CamelSExpTerm **terms;
	gint i, size = 0;
	GScanner *gs = sexp->priv->scanner;
	GSList *list = NULL, *l;

	p (printf ("parsing values\n"));

	while ( (token = g_scanner_peek_next_token (gs)) != G_TOKEN_EOF
		&& token != ')') {
		list = g_slist_prepend (list, parse_value (sexp));
		size++;
	}

	/* go over the list, and put them backwards into the term array */
	terms = g_malloc (size * sizeof (*terms));
	l = list;
	for (i = size - 1; i >= 0; i--) {
		if (!l || !l->data) {
			if (!l)
				g_warn_if_fail (l != NULL);
			if (l && !l->data)
				g_warn_if_fail (l->data != NULL);

			g_slist_free (list);
			g_free (terms);

			*len = 0;

			return NULL;
		}

		terms[i] = l->data;
		l = g_slist_next (l);
	}
	g_slist_free (list);

	p (printf ("found %d subterms\n", size));
	*len = size;

	p (printf ("done parsing values\n"));
	return terms;
}

/**
 * camel_sexp_parse_value: (skip)
 * @sexp: a #CamelSExp
 *
 * Returns: (nullable) (transfer none): a #CamelSExpTerm of the next token, or %NULL when there is none.
 *
 * Since: 3.4
 **/
CamelSExpTerm *
camel_sexp_parse_value (CamelSExp *sexp)
{
	return parse_value (sexp);
}

static CamelSExpTerm *
parse_value (CamelSExp *sexp)
{
	gint token, negative = FALSE;
	CamelSExpTerm *term = NULL;
	GScanner *gs = sexp->priv->scanner;
	CamelSExpSymbol *sym;

	p (printf ("parsing value\n"));

	token = g_scanner_get_next_token (gs);
	switch (token) {
	case G_TOKEN_EOF:
		break;
	case G_TOKEN_LEFT_PAREN:
		p (printf ("got brace, its a list!\n"));
		return parse_list (sexp, TRUE);
	case G_TOKEN_STRING:
		p (printf ("got string '%s'\n", g_scanner_cur_value (gs).v_string));
		term = parse_term_new (sexp, CAMEL_SEXP_TERM_STRING);
		term->value.string = g_strdup (g_scanner_cur_value (gs).v_string);
		break;
	case '-':
		p (printf ("got negative int?\n"));
		token = g_scanner_get_next_token (gs);
		if (token != G_TOKEN_INT) {
			camel_sexp_fatal_error (sexp, "Invalid format for a integer value");
			return NULL;
		}

		negative = TRUE;
		/* fall through... */
	case G_TOKEN_INT:
		term = parse_term_new (sexp, CAMEL_SEXP_TERM_INT);
		term->value.number = g_scanner_cur_value (gs).v_int;
		if (negative)
			term->value.number = -term->value.number;
		p (printf ("got gint %d\n", term->value.number));
		break;
	case '#': {
		gchar *str;

		p (printf ("got bool?\n"));
		token = g_scanner_get_next_token (gs);
		if (token != G_TOKEN_IDENTIFIER) {
			camel_sexp_fatal_error (sexp, "Invalid format for a boolean value");
			return NULL;
		}

		str = g_scanner_cur_value (gs).v_identifier;

		g_return_val_if_fail (str != NULL, NULL);
		if (!(strlen (str) == 1 && (str[0] == 't' || str[0] == 'f'))) {
			camel_sexp_fatal_error (sexp, "Invalid format for a boolean value");
			return NULL;
		}

		term = parse_term_new (sexp, CAMEL_SEXP_TERM_BOOL);
		term->value.boolean = (str[0] == 't');
		break; }
	case G_TOKEN_SYMBOL:
		sym = g_scanner_cur_value (gs).v_symbol;
		p (printf ("got symbol '%s'\n", sym->name));
		switch (sym->type) {
		case CAMEL_SEXP_TERM_FUNC:
		case CAMEL_SEXP_TERM_IFUNC:
			/* this is basically invalid, since we can't use function
			 * pointers, but let the runtime catch it ... */
			term = parse_term_new (sexp, sym->type);
			term->value.func.sym = sym;
			term->value.func.terms = parse_values (sexp, &term->value.func.termcount);
			break;
		case CAMEL_SEXP_TERM_VAR:
			term = parse_term_new (sexp, sym->type);
			term->value.var = sym;
			break;
		default:
			camel_sexp_fatal_error (sexp, "Invalid symbol type: %s: %d", sym->name, sym->type);
		}
		break;
	case G_TOKEN_IDENTIFIER:
		p (printf ("got unknown identifider '%s'\n", g_scanner_cur_value (gs).v_identifier));
		camel_sexp_fatal_error (sexp, "Unknown identifier: %s", g_scanner_cur_value (gs).v_identifier);
		break;
	default:
		camel_sexp_fatal_error (sexp, "Unexpected token encountered: %d", token);
	}
	p (printf ("done parsing value\n"));

	return term;
}

/* FIXME: this needs some robustification */
static CamelSExpTerm *
parse_list (CamelSExp *sexp,
            gint gotbrace)
{
	gint token;
	CamelSExpTerm *term = NULL;
	GScanner *gs = sexp->priv->scanner;

	p (printf ("parsing list\n"));
	if (gotbrace)
		token = '(';
	else
		token = g_scanner_get_next_token (gs);
	if (token =='(') {
		token = g_scanner_get_next_token (gs);
		switch (token) {
		case G_TOKEN_SYMBOL: {
			CamelSExpSymbol *sym;

			sym = g_scanner_cur_value (gs).v_symbol;
			p (printf ("got funciton: %s\n", sym->name));
			term = parse_term_new (sexp, sym->type);
			p (printf ("created new list %p\n", t));
			/* if we have a variable, find out its base type */
			while (sym->type == CAMEL_SEXP_TERM_VAR) {
				sym = ((CamelSExpTerm *)(sym->data))->value.var;
			}
			if (sym->type == CAMEL_SEXP_TERM_FUNC
			    || sym->type == CAMEL_SEXP_TERM_IFUNC) {
				term->value.func.sym = sym;
				term->value.func.terms = parse_values (sexp, &term->value.func.termcount);
			} else {
				parse_term_free (sexp, term);
				camel_sexp_fatal_error (sexp, "Trying to call variable as function: %s", sym->name);
			}
			break; }
		case G_TOKEN_IDENTIFIER:
			camel_sexp_fatal_error (sexp, "Unknown identifier: %s", g_scanner_cur_value (gs).v_identifier);
			break;
		case G_TOKEN_LEFT_PAREN:
			return parse_list (sexp, TRUE);
		default:
			camel_sexp_fatal_error (sexp, "Unexpected token encountered: %d", token);
		}
		token = g_scanner_get_next_token (gs);
		if (token != ')') {
			camel_sexp_fatal_error (sexp, "Missing ')'");
		}
	} else {
		camel_sexp_fatal_error (sexp, "Missing '('");
	}

	p (printf ("returning list %p\n", term));

	return term;
}

static void
free_symbol (gpointer key,
             gpointer value,
             gpointer data)
{
	CamelSExpSymbol *sym = value;

	g_free (sym->name);
	g_free (sym);
}

static void
camel_sexp_finalize (GObject *object)
{
	CamelSExp *sexp = (CamelSExp *) object;

	if (sexp->priv->tree) {
		parse_term_free (sexp, sexp->priv->tree);
		sexp->priv->tree = NULL;
	}

	camel_memchunk_destroy (sexp->priv->term_chunks);
	camel_memchunk_destroy (sexp->priv->result_chunks);

	g_scanner_scope_foreach_symbol (sexp->priv->scanner, 0, free_symbol, NULL);
	g_scanner_destroy (sexp->priv->scanner);

	g_free (sexp->priv->error);
	sexp->priv->error = NULL;

	/* Chain up to parent's finalize() method. */
	G_OBJECT_CLASS (camel_sexp_parent_class)->finalize (object);
}

static void
camel_sexp_class_init (CamelSExpClass *class)
{
	GObjectClass *object_class;

	g_type_class_add_private (class, sizeof (CamelSExpPrivate));

	object_class = G_OBJECT_CLASS (class);
	object_class->finalize = camel_sexp_finalize;
}

/* 'builtin' functions */
static const struct {
	const gchar *name;
	CamelSExpFunc func;
	gint type;	/* set to 1 if a function can perform shortcut
			 * evaluation, or doesn't execute everything,
			 * 0 otherwise */
} symbols[] = {
	{ "and",         (CamelSExpFunc) term_eval_and, 1 },
	{ "or",          (CamelSExpFunc) term_eval_or, 1 },
	{ "not",         (CamelSExpFunc) term_eval_not, 0 },
	{ "<",           (CamelSExpFunc) term_eval_lt, 1 },
	{ ">",           (CamelSExpFunc) term_eval_gt, 1 },
	{ "=",           (CamelSExpFunc) term_eval_eq, 1 },
	{ "+",           (CamelSExpFunc) term_eval_plus, 0 },
	{ "-",           (CamelSExpFunc) term_eval_sub, 0 },
	{ "cast-int",    (CamelSExpFunc) term_eval_castint, 0 },
	{ "cast-string", (CamelSExpFunc) term_eval_caststring, 0 },
	{ "if",          (CamelSExpFunc) term_eval_if, 1 },
	{ "begin",       (CamelSExpFunc) term_eval_begin, 1 },
};

static void
camel_sexp_init (CamelSExp *sexp)
{
	gint i;

	sexp->priv = G_TYPE_INSTANCE_GET_PRIVATE (sexp, CAMEL_TYPE_SEXP, CamelSExpPrivate);

	sexp->priv->scanner = g_scanner_new (&scanner_config);
	sexp->priv->term_chunks = camel_memchunk_new (16, sizeof (CamelSExpTerm));
	sexp->priv->result_chunks = camel_memchunk_new (16, sizeof (CamelSExpResult));

	/* load in builtin symbols? */
	for (i = 0; i < G_N_ELEMENTS (symbols); i++) {
		if (symbols[i].type == 1) {
			camel_sexp_add_ifunction (
				sexp, 0, symbols[i].name,
				(CamelSExpIFunc) symbols[i].func,
				(gpointer) &symbols[i]);
		} else {
			camel_sexp_add_function (
				sexp, 0, symbols[i].name,
				symbols[i].func,
				(gpointer) &symbols[i]);
		}
	}
}

/**
 * camel_sexp_new:
 *
 * Returns: (transfer full): a new #CamelSExp
 *
 * Since: 3.4
 **/
CamelSExp *
camel_sexp_new (void)
{
	return g_object_new (CAMEL_TYPE_SEXP, NULL);
}

/**
 * camel_sexp_add_function:
 * @sexp: a #CamelSExp
 * @scope: a scope
 * @name: a function name
 * @func: (scope call) (closure user_data): a function callback
 * @user_data: user data for @func
 *
 * Adds a function symbol which can not perform short evaluation.
 * Use camel_sexp_add_ifunction() for functions which can.
 *
 * Since: 3.4
 **/
void
camel_sexp_add_function (CamelSExp *sexp,
                         guint scope,
                         const gchar *name,
                         CamelSExpFunc func,
                         gpointer user_data)
{
	CamelSExpSymbol *sym;

	g_return_if_fail (CAMEL_IS_SEXP (sexp));
	g_return_if_fail (name != NULL);

	camel_sexp_remove_symbol (sexp, scope, name);

	sym = g_malloc0 (sizeof (*sym));
	sym->name = g_strdup (name);
	sym->f.func = func;
	sym->type = CAMEL_SEXP_TERM_FUNC;
	sym->data = user_data;

	g_scanner_scope_add_symbol (sexp->priv->scanner, scope, sym->name, sym);
}

/**
 * camel_sexp_add_ifunction:
 * @sexp: a #CamelSExp
 * @scope: a scope
 * @name: a function name
 * @ifunc: (scope call) (closure user_data): a function callback
 * @user_data: user data for @ifunc
 *
 * Adds a function symbol which can perform short evaluation,
 * or doesn't execute everything. Use camel_sexp_add_function()
 * for any other types of the function symbols.
 *
 * Since: 3.4
 **/
void
camel_sexp_add_ifunction (CamelSExp *sexp,
                          guint scope,
                          const gchar *name,
                          CamelSExpIFunc ifunc,
                          gpointer user_data)
{
	CamelSExpSymbol *sym;

	g_return_if_fail (CAMEL_IS_SEXP (sexp));
	g_return_if_fail (name != NULL);

	camel_sexp_remove_symbol (sexp, scope, name);

	sym = g_malloc0 (sizeof (*sym));
	sym->name = g_strdup (name);
	sym->f.ifunc = ifunc;
	sym->type = CAMEL_SEXP_TERM_IFUNC;
	sym->data = user_data;

	g_scanner_scope_add_symbol (sexp->priv->scanner, scope, sym->name, sym);
}

/**
 * camel_sexp_add_variable:
 * @sexp: a #CamelSExp
 * @scope: a scope
 * @name: a variable name
 * @value: a variable value, as a #CamelSExpTerm
 *
 * Adds a variable named @name to the given @scope, set to the given @value.
 *
 * Since: 3.4
 **/
void
camel_sexp_add_variable (CamelSExp *sexp,
                         guint scope,
                         const gchar *name,
                         CamelSExpTerm *value)
{
	CamelSExpSymbol *sym;

	g_return_if_fail (CAMEL_IS_SEXP (sexp));
	g_return_if_fail (name != NULL);

	sym = g_malloc0 (sizeof (*sym));
	sym->name = g_strdup (name);
	sym->type = CAMEL_SEXP_TERM_VAR;
	sym->data = value;

	g_scanner_scope_add_symbol (sexp->priv->scanner, scope, sym->name, sym);
}

/**
 * camel_sexp_remove_symbol:
 * @sexp: a #CamelSExp
 * @scope: a scope
 * @name: a symbol name
 *
 * Revoes a symbol from a scope.
 *
 * Since: 3.4
 **/
void
camel_sexp_remove_symbol (CamelSExp *sexp,
                          guint scope,
                          const gchar *name)
{
	gint oldscope;
	CamelSExpSymbol *sym;

	g_return_if_fail (CAMEL_IS_SEXP (sexp));
	g_return_if_fail (name != NULL);

	oldscope = g_scanner_set_scope (sexp->priv->scanner, scope);
	sym = g_scanner_lookup_symbol (sexp->priv->scanner, name);
	g_scanner_scope_remove_symbol (sexp->priv->scanner, scope, name);
	g_scanner_set_scope (sexp->priv->scanner, oldscope);
	if (sym != NULL) {
		g_free (sym->name);
		g_free (sym);
	}
}

/**
 * camel_sexp_set_scope:
 * @sexp: a #CamelSExp
 * @scope: a scope to set
 *
 * sets the current scope for the scanner.
 *
 * Returns: the previous scope id
 *
 * Since: 3.4
 **/
gint
camel_sexp_set_scope (CamelSExp *sexp,
                      guint scope)
{
	g_return_val_if_fail (CAMEL_IS_SEXP (sexp), 0);

	return g_scanner_set_scope (sexp->priv->scanner, scope);
}

/**
 * camel_sexp_input_text:
 * @sexp: a #CamelSExp
 * @text: a text buffer to scan
 * @len: the length of the text buffer
 *
 * Prepares to scan a text buffer.
 *
 * Since: 3.4
 **/
void
camel_sexp_input_text (CamelSExp *sexp,
                       const gchar *text,
                       gint len)
{
	g_return_if_fail (CAMEL_IS_SEXP (sexp));
	g_return_if_fail (text != NULL);

	g_scanner_input_text (sexp->priv->scanner, text, len);
}

/**
 * camel_sexp_input_file:
 * @sexp: a #CamelSExp
 * @fd: a file descriptor
 *
 * Prepares to scan a file.
 *
 * Since: 3.4
 **/
void
camel_sexp_input_file (CamelSExp *sexp,
                       gint fd)
{
	g_return_if_fail (CAMEL_IS_SEXP (sexp));

	g_scanner_input_file (sexp->priv->scanner, fd);
}

/**
 * camel_sexp_parse:
 * @sexp: a #CamelSExp
 *
 * Since: 3.4
 **/
gint
camel_sexp_parse (CamelSExp *sexp)
{
	g_return_val_if_fail (CAMEL_IS_SEXP (sexp), -1);

	if (setjmp (sexp->priv->failenv)) {
		g_warning ("Error in parsing: %s", sexp->priv->error);
		return -1;
	}

	if (sexp->priv->tree)
		parse_term_free (sexp, sexp->priv->tree);

	sexp->priv->tree = parse_value (sexp);

	return 0;
}

/**
 * camel_sexp_eval: (skip)
 * @sexp: a #CamelSExp
 *
 * Since: 3.4
 **/
CamelSExpResult *
camel_sexp_eval (CamelSExp *sexp)
{
	g_return_val_if_fail (CAMEL_IS_SEXP (sexp), NULL);
	g_return_val_if_fail (sexp->priv->tree != NULL, NULL);

	if (setjmp (sexp->priv->failenv)) {
		g_warning ("Error in execution: %s", sexp->priv->error);
		return NULL;
	}

	return camel_sexp_term_eval (sexp, sexp->priv->tree);
}

/**
 * e_cal_backend_sexp_evaluate_occur_times:
 * @sexp: a #CamelSExp
 * @start: Start of the time window will be stored here.
 * @end: End of the time window will be stored here.
 *
 * Determines biggest time window given by expressions "occur-in-range" in sexp.
 *
 * Since: 3.4
 */
gboolean
camel_sexp_evaluate_occur_times (CamelSExp *sexp,
                                 time_t *start,
                                 time_t *end)
{
	CamelSExpResult *result;
	gboolean generator;
	g_return_val_if_fail (CAMEL_IS_SEXP (sexp), FALSE);
	g_return_val_if_fail (sexp->priv->tree != NULL, FALSE);
	g_return_val_if_fail (start != NULL, FALSE);
	g_return_val_if_fail (end != NULL, FALSE);

	*start = *end = -1;

	if (setjmp (sexp->priv->failenv)) {
		g_warning ("Error in execution: %s", sexp->priv->error);
		return FALSE;
	}

	result = camel_sexp_term_evaluate_occur_times (
		sexp, sexp->priv->tree, start, end);
	generator = result->time_generator;

	if (generator) {
		*start = result->occuring_start;
		*end = result->occuring_end;
	}

	camel_sexp_result_free (sexp, result);

	return generator;
}

/**
 * camel_sexp_encode_bool:
 * @string: Destination #GString
 * @v_bool: the value
 *
 * Encode a bool into an s-expression @string.  Bools are
 * encoded using #t #f syntax.
 *
 * Since: 3.4
 **/
void
camel_sexp_encode_bool (GString *string,
                        gboolean v_bool)
{
	if (v_bool)
		g_string_append (string, " #t");
	else
		g_string_append (string, " #f");
}

/**
 * camel_sexp_encode_string:
 * @string: Destination #GString
 * @v_string: String expression.
 *
 * Add a c string @v_string to the s-expression stored in
 * the gstring @s.  Quotes are added, and special characters
 * are escaped appropriately.
 *
 * Since: 3.4
 **/
void
camel_sexp_encode_string (GString *string,
                          const gchar *v_string)
{
	gchar c;
	const gchar *p;

	if (v_string == NULL)
		p = "";
	else
		p = v_string;
	g_string_append (string, " \"");
	while ((c = *p++)) {
		if (c == '\\' || c == '\"' || c == '\'')
			g_string_append_c (string, '\\');
		g_string_append_c (string, c);
	}
	g_string_append (string, "\"");
}

#ifdef TESTER
gint
main (gint argc,
      gchar **argv)
{
	CamelSExp *sexp;
	gchar *t = "(+ \"foo\" \"\\\"\" \"bar\" \"\\\\ blah \\x \")";
	CamelSExpResult *result;

	sexp = camel_sexp_new ();

	camel_sexp_add_variable (sexp, 0, "test", NULL);

	if (argc < 2 || !argv[1])
		return;

	camel_sexp_input_text (sexp, t, t);
	camel_sexp_parse (sexp);

	if (sexp->priv->tree)
		parse_dump_term (sexp->priv->tree, 0);

	result = camel_sexp_eval (sexp);
	if (result) {
		eval_dump_result (result, 0);
	} else {
		printf ("no result?|\n");
	}

	return 0;
}
#endif
