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
 * Authors: Chris Lahey <clahey@ximian.com>
 */

#if !defined (__LIBEDATA_CAL_H_INSIDE__) && !defined (LIBEDATA_CAL_COMPILATION)
#error "Only <libedata-cal/libedata-cal.h> should be included directly."
#endif

#ifndef E_CAL_BACKEND_SEXP_H
#define E_CAL_BACKEND_SEXP_H

#include <libecal/libecal.h>

/* Standard GObject macros */
#define E_TYPE_CAL_BACKEND_SEXP \
	(e_cal_backend_sexp_get_type ())
#define E_CAL_BACKEND_SEXP(obj) \
	(G_TYPE_CHECK_INSTANCE_CAST \
	((obj), E_TYPE_CAL_BACKEND_SEXP, ECalBackendSExp))
#define E_CAL_BACKEND_SEXP_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_CAST \
	((cls), E_TYPE_CAL_BACKEND_SEXP, ECalBackendSExpClass))
#define E_IS_CAL_BACKEND_SEXP(obj) \
	(G_TYPE_CHECK_INSTANCE_TYPE \
	((obj), E_TYPE_CAL_BACKEND_SEXP))
#define E_IS_CAL_BACKEND_SEXP_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_TYPE \
	((cls), E_TYPE_CAL_BACKEND_SEXP))
#define E_CAL_BACKEND_SEXP_GET_CLASS(cls) \
	(G_TYPE_INSTANCE_GET_CLASS \
	((obj), E_TYPE_CAL_BACKEND_SEXP, CALBackendSExpClass))

G_BEGIN_DECLS

typedef struct _ECalBackendSExp ECalBackendSExp;
typedef struct _ECalBackendSExpClass ECalBackendSExpClass;
typedef struct _ECalBackendSExpPrivate ECalBackendSExpPrivate;

/**
 * ECalBackendSexp:
 *
 * Contains only private data that should be read and manipulated using the
 * functions below.
 */
struct _ECalBackendSExp {
	/*< private >*/
	GObject parent;
	ECalBackendSExpPrivate *priv;
};

/**
 * ECalBackendSexpClass:
 *
 * Class structure for the #ECalBackendSexp class.
 */
struct _ECalBackendSExpClass {
	/*< private >*/
	GObjectClass parent_class;
};

GType		e_cal_backend_sexp_get_type	(void) G_GNUC_CONST;
ECalBackendSExp *
		e_cal_backend_sexp_new		(const gchar *text);
const gchar *	e_cal_backend_sexp_text		(ECalBackendSExp *sexp);

gboolean	e_cal_backend_sexp_match_object	(ECalBackendSExp *sexp,
						 const gchar *object,
						 ETimezoneCache *cache);
gboolean	e_cal_backend_sexp_match_comp	(ECalBackendSExp *sexp,
						 ECalComponent *comp,
						 ETimezoneCache *cache);

/* Default implementations of time functions for use by subclasses */

ESExpResult *	e_cal_backend_sexp_func_time_now
						(ESExp *esexp,
						 gint argc,
						 ESExpResult **argv,
						 gpointer data);
ESExpResult *	e_cal_backend_sexp_func_make_time
						(ESExp *esexp,
						 gint argc,
						 ESExpResult **argv,
						 gpointer data);
ESExpResult *	e_cal_backend_sexp_func_time_add_day
						(ESExp *esexp,
						 gint argc,
						 ESExpResult **argv,
						 gpointer data);
ESExpResult *	e_cal_backend_sexp_func_time_day_begin
						(ESExp *esexp,
						 gint argc,
						 ESExpResult **argv,
						 gpointer data);
ESExpResult *	e_cal_backend_sexp_func_time_day_end
						(ESExp *esexp,
						 gint argc,
						 ESExpResult **argv,
						 gpointer data);
gboolean	e_cal_backend_sexp_evaluate_occur_times
						(ECalBackendSExp *sexp,
						 time_t *start,
						 time_t *end);

G_END_DECLS

#endif /* E_CAL_BACKEND_SEXP_H */
