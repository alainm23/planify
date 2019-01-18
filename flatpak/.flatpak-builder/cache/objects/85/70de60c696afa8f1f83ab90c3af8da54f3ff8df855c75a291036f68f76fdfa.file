/*
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

#if !defined (__LIBEDATASERVER_H_INSIDE__) && !defined (LIBEDATASERVER_COMPILATION)
#error "Only <libedataserver/libedataserver.h> should be included directly."
#endif

#ifndef _E_SEXP_H
#define _E_SEXP_H

#include <setjmp.h>
#include <time.h>
#include <glib.h>

#include <glib-object.h>

#define E_TYPE_SEXP            (e_sexp_get_type ())
#define E_SEXP(obj)            (G_TYPE_CHECK_INSTANCE_CAST ((obj), E_TYPE_SEXP, ESExp))
#define E_SEXP_CLASS(cls)      (G_TYPE_CHECK_CLASS_CAST ((cls), E_TYPE_SEXP, ESExpClass))
#define E_IS_SEXP(obj)         (G_TYPE_CHECK_INSTANCE_TYPE ((obj), E_TYPE_SEXP))
#define E_IS_SEXP_CLASS(cls)   (G_TYPE_CHECK_CLASS_TYPE ((cls), E_TYPE_SEXP))
#define E_SEXP_GET_CLASS(obj)  (G_TYPE_INSTANCE_GET_CLASS ((obj), E_TYPE_SEXP, ESExpClass))

G_BEGIN_DECLS

typedef struct _ESExp        ESExp;
typedef struct _ESExpClass   ESExpClass;
typedef struct _ESExpPrivate ESExpPrivate;

typedef struct _ESExpSymbol ESExpSymbol;
typedef struct _ESExpResult ESExpResult;
typedef struct _ESExpTerm ESExpTerm;

typedef enum {
	ESEXP_RES_ARRAY_PTR=0,	/* type is a ptrarray, what it points to is implementation dependant */
	ESEXP_RES_INT,		/* type is a number */
	ESEXP_RES_STRING,	/* type is a pointer to a single string */
	ESEXP_RES_BOOL,		/* boolean type */
	ESEXP_RES_TIME,		/* time_t type */
	ESEXP_RES_UNDEFINED	/* unknown type */
} ESExpResultType;

struct _ESExpResult {
	ESExpResultType type;
	union {
		GPtrArray *ptrarray;
		gint number;
		gchar *string;
		gint boolean;
		time_t time;
	} value;
	gboolean time_generator;
	time_t occuring_start;
	time_t occuring_end;
};

/**
 * ESExpFunc:
 * @sexp: a #ESExp
 * @argc: count of arguments
 * @argv: (in) (array length=argc): array of values of the arguments
 * @user_data: user data as passed to e_sexp_add_function()
 *
 * Callback type for function symbols used with e_sexp_add_function().
 *
 * Returns: Result of the function call, allocated by e_sexp_result_new().
 */
typedef struct _ESExpResult *(ESExpFunc)(struct _ESExp *sexp,
					 gint argc,
					 struct _ESExpResult **argv,
					 gpointer user_data);

/**
 * ESExpIFunc:
 * @sexp: a #ESExp
 * @argc: count of arguments
 * @argv: (in) (array length=argc): array of values of the arguments
 * @user_data: user data as passed to e_sexp_add_ifunction()
 *
 * Callback type for function symbols used with e_sexp_add_ifunction().
 *
 * Returns: Result of the function call, allocated by e_sexp_result_new().
 */
typedef struct _ESExpResult *(ESExpIFunc)(struct _ESExp *sexp,
					  gint argc,
					  struct _ESExpTerm **argv,
					  gpointer user_data);

typedef enum {
	ESEXP_TERM_INT	= 0,	/* integer literal */
	ESEXP_TERM_BOOL,	/* boolean literal */
	ESEXP_TERM_STRING,	/* string literal */
	ESEXP_TERM_TIME,	/* time_t literal (number of seconds past the epoch) */
	ESEXP_TERM_FUNC,	/* normal function, arguments are evaluated before calling */
	ESEXP_TERM_IFUNC,	/* immediate function, raw terms are arguments */
	ESEXP_TERM_VAR		/* variable reference */
} ESExpTermType;

struct _ESExpSymbol {
	gint type;		/* ESEXP_TERM_FUNC or ESEXP_TERM_VAR */
	gchar *name;
	gpointer data;
	union {
		ESExpFunc *func;
		ESExpIFunc *ifunc;
	} f;
};

struct _ESExpTerm {
	ESExpTermType type;
	union {
		gchar *string;
		gint number;
		gint boolean;
		time_t time;
		struct {
			struct _ESExpSymbol *sym;
			struct _ESExpTerm **terms;
			gint termcount;
		} func;
		struct _ESExpSymbol *var;
	} value;
};

struct _ESExp {
	GObject parent_object;

	ESExpPrivate *priv;
};

struct _ESExpClass {
	GObjectClass parent_class;
};

GType           e_sexp_get_type		(void);
ESExp	       *e_sexp_new		(void);
void		e_sexp_add_function	(ESExp *sexp,
					 gint scope,
					 const gchar *name,
					 ESExpFunc *func,
					 gpointer user_data);
void		e_sexp_add_ifunction	(ESExp *sexp,
					 gint scope,
					 const gchar *name,
					 ESExpIFunc *func,
					 gpointer user_data);
void		e_sexp_add_variable	(ESExp *sexp,
					 gint scope,
					 gchar *name,
					 ESExpTerm *value);
void		e_sexp_remove_symbol	(ESExp *sexp,
					 gint scope,
					 const gchar *name);
gint		e_sexp_set_scope	(ESExp *sexp,
					 gint scope);

void		e_sexp_input_text	(ESExp *sexp,
					 const gchar *text,
					 gint len);
void		e_sexp_input_file	(ESExp *sexp,
					 gint fd);

gint		e_sexp_parse		(ESExp *sexp);
ESExpResult    *e_sexp_eval		(ESExp *sexp);

ESExpResult    *e_sexp_term_eval	(ESExp *sexp,
					 ESExpTerm *t);
ESExpResult    *e_sexp_result_new	(ESExp *sexp,
					 gint type);
void		e_sexp_result_free	(ESExp *sexp,
					 ESExpResult *t);

/* used in normal functions if they have to abort, to free their arguments */
void		e_sexp_resultv_free	(ESExp *sexp,
					 gint argc,
					 ESExpResult **argv);

/* utility functions for creating s-exp strings. */
void		e_sexp_encode_bool	(GString *s,
					 gboolean state);
void		e_sexp_encode_string	(GString *s,
					 const gchar *string);

/* only to be called from inside a callback to signal a fatal execution error */
void		e_sexp_fatal_error	(ESExp *sexp,
					 const gchar *why,
					 ...) G_GNUC_NORETURN;

/* return the error string */
const gchar *	e_sexp_get_error	(ESExp *sexp);

ESExpTerm * 	e_sexp_parse_value	(ESExp *sexp);

gboolean	e_sexp_evaluate_occur_times
					(ESExp *sexp,
					 time_t *start,
					 time_t *end);

G_END_DECLS

#endif /* _E_SEXP_H */
