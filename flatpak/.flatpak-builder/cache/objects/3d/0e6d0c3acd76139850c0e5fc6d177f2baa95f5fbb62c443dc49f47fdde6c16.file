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
 */

/**
 * SECTION: e-cal-backend-sexp
 * @include: libedata-cal/libedata-cal.h
 * @short_description: A utility for comparing #ECalComponent(s) with search expressions.
 *
 * This API is an all purpose utility for comparing #ECalComponent(s) with search expressions
 * and is used by various backends to implement component filtering and searching.
 */

#include "evolution-data-server-config.h"

#include <string.h>
#include <glib/gi18n-lib.h>

#include "e-cal-backend-sexp.h"

#define E_CAL_BACKEND_SEXP_GET_PRIVATE(obj) \
	(G_TYPE_INSTANCE_GET_PRIVATE \
	((obj), E_TYPE_CAL_BACKEND_SEXP, ECalBackendSExpPrivate))

G_DEFINE_TYPE (ECalBackendSExp, e_cal_backend_sexp, G_TYPE_OBJECT)

typedef struct _SearchContext SearchContext;

struct _ECalBackendSExpPrivate {
	ESExp *search_sexp;
	gchar *text;
	SearchContext *search_context;
	GMutex search_context_lock;
};

struct _SearchContext {
	ECalComponent *comp;
	ETimezoneCache *cache;
	gboolean occurs;
	gint occurrences_count;

	gboolean expr_range_set;
	time_t expr_range_start;
	time_t expr_range_end;
};

static ESExpResult *func_is_completed (ESExp *esexp, gint argc, ESExpResult **argv, gpointer data);

/* (uid? UID)
 *
 * UID - the uid of the component
 *
 * Returns a boolean indicating whether the component has the given UID
 */
static ESExpResult *
func_uid (ESExp *esexp,
          gint argc,
          ESExpResult **argv,
          gpointer data)
{
	SearchContext *ctx = data;
	const gchar *uid = NULL, *arg_uid;
	gboolean equal;
	ESExpResult *result;

	/* Check argument types */

	if (argc != 1) {
		e_sexp_fatal_error (
			esexp, _("“%s” expects one argument"),
			"uid");
		return NULL;
	}

	if (argv[0]->type != ESEXP_RES_STRING) {
		e_sexp_fatal_error (
			esexp, _("“%s” expects the first "
			"argument to be a string"),
			"uid");
		return NULL;
	}

	arg_uid = argv[0]->value.string;
	e_cal_component_get_uid (ctx->comp, &uid);

	if (!arg_uid && !uid)
		equal = TRUE;
	else if ((!arg_uid || !uid) && arg_uid != uid)
		equal = FALSE;
	else if (e_util_utf8_strstrcase (arg_uid, uid) != NULL && strlen (arg_uid) == strlen (uid))
		equal = TRUE;
	else
		equal = FALSE;

	result = e_sexp_result_new (esexp, ESEXP_RES_BOOL);
	result->value.boolean = equal;

	return result;
}

static gboolean
check_instance_time_range_cb (ECalComponent *comp,
                              time_t instance_start,
                              time_t instance_end,
                              gpointer data)
{
	SearchContext *ctx = data;

	/* if we get called, the event has an occurrence in the given time range */
	ctx->occurs = TRUE;

	return FALSE;
}

static icaltimezone *
resolve_tzid (const gchar *tzid,
              gpointer user_data)
{
	SearchContext *ctx = user_data;

	if (tzid == NULL || *tzid == '\0')
		return NULL;

	return e_timezone_cache_get_timezone (ctx->cache, tzid);
}

/* (occur-in-time-range? START END TZLOC)
 *
 * START - time_t, start of the time range, in UTC
 * END - time_t, end of the time range, in UTC
 * TZLOC - optional string with timezone location to use
 *        as default timezone; if not set, UTC is used
 *
 * Returns a boolean indicating whether the component has any occurrences in the
 * specified time range.
 */
static ESExpResult *
func_occur_in_time_range (ESExp *esexp,
                          gint argc,
                          ESExpResult **argv,
                          gpointer data)
{
	SearchContext *ctx = data;
	time_t start, end;
	ESExpResult *result;
	icaltimezone *default_zone = NULL;

	/* Check argument types */

	if (argc != 2 && argc != 3) {
		e_sexp_fatal_error (
			esexp, _("“%s” expects two or three arguments"),
			"occur-in-time-range");
		return NULL;
	}

	if (argv[0]->type != ESEXP_RES_TIME) {
		e_sexp_fatal_error (
			esexp, _("“%s” expects the first "
			"argument to be a time_t"),
			"occur-in-time-range");
		return NULL;
	}
	start = argv[0]->value.time;

	if (argv[1]->type != ESEXP_RES_TIME) {
		e_sexp_fatal_error (
			esexp, _("“%s” expects the second "
			"argument to be a time_t"),
			"occur-in-time-range");
		return NULL;
	}
	end = argv[1]->value.time;

	if (argc == 3) {
		if (argv[2]->type != ESEXP_RES_STRING) {
			e_sexp_fatal_error (
				esexp, _("“%s” expects the third "
				"argument to be a string"),
				"occur-in-time-range");
			return NULL;
		}

		default_zone = resolve_tzid (argv[2]->value.string, ctx);
	}

	if (!default_zone)
		default_zone = icaltimezone_get_utc_timezone ();

	/* See if the object occurs in the specified time range */
	ctx->occurs = FALSE;
	e_cal_recur_generate_instances (
		ctx->comp, start, end,
		(ECalRecurInstanceFn) check_instance_time_range_cb,
		ctx, resolve_tzid, ctx,
		default_zone);

	result = e_sexp_result_new (esexp, ESEXP_RES_BOOL);
	result->value.boolean = ctx->occurs;

	return result;
}

static gboolean
count_instances_time_range_cb (ECalComponent *comp,
                               time_t instance_start,
                               time_t instance_end,
                               gpointer data)
{
	SearchContext *ctx = data;

	ctx->occurrences_count++;

	return TRUE;
}

/*
 * (occurrences-count? START END)
 * (occurrences-count?)
 *
 * Counts occurrences either in the given time range (the first variant)
 * or in the time range defined by the expression itself (the second variant).
 * If the time range cannot be determined, then -1 is returned.
 */
static ESExpResult *
func_occurrences_count (ESExp *esexp,
                        gint argc,
                        ESExpResult **argv,
                        gpointer data)
{
	SearchContext *ctx = data;
	time_t start, end;
	ESExpResult *result;
	icaltimezone *default_zone;

	/* Check argument types */

	if (argc != 2 && argc != 0) {
		e_sexp_fatal_error (
			esexp, _("“%s” expects none or two arguments"),
			"occurrences-count");
		return NULL;
	}

	if (argc == 2) {
		if (argv[0]->type != ESEXP_RES_TIME) {
			e_sexp_fatal_error (
				esexp, _("“%s” expects the first argument to be a time_t"),
				"occurrences-count");
			return NULL;
		}
		start = argv[0]->value.time;

		if (argv[1]->type != ESEXP_RES_TIME) {
			e_sexp_fatal_error (
				esexp, _("“%s” expects the second argument to be a time_t"),
				"occurrences-count");
			return NULL;
		}
		end = argv[1]->value.time;
	} else if (ctx->expr_range_set) {
		start = ctx->expr_range_start;
		end = ctx->expr_range_end;
	} else {
		result = e_sexp_result_new (esexp, ESEXP_RES_INT);
		result->value.number = -1;

		return result;
	}

	default_zone = icaltimezone_get_utc_timezone ();

	ctx->occurrences_count = 0;
	e_cal_recur_generate_instances (
		ctx->comp, start, end,
		count_instances_time_range_cb, ctx,
		resolve_tzid, ctx, default_zone);

	result = e_sexp_result_new (esexp, ESEXP_RES_INT);
	result->value.number = ctx->occurrences_count;

	return result;
}

static ESExpResult *
func_due_in_time_range (ESExp *esexp,
                        gint argc,
                        ESExpResult **argv,
                        gpointer data)
{
	SearchContext *ctx = data;
	time_t start, end;
	ESExpResult *result;
	icaltimezone *zone;
	ECalComponentDateTime dt;
	time_t due_t;
	gboolean retval;

	/* Check argument types */

	if (argc != 2) {
		e_sexp_fatal_error (
			esexp, _("“%s” expects two arguments"),
				"due-in-time-range");
		return NULL;
	}

	if (argv[0]->type != ESEXP_RES_TIME) {
		e_sexp_fatal_error (
			esexp, _("“%s” expects the first "
			"argument to be a time_t"),
			"due-in-time-range");
		return NULL;
	}

	start = argv[0]->value.time;

	if (argv[1]->type != ESEXP_RES_TIME) {
		e_sexp_fatal_error (
			esexp, _("“%s” expects the second "
			"argument to be a time_t"),
			"due-in-time-range");
		return NULL;
	}

	end = argv[1]->value.time;
	e_cal_component_get_due (ctx->comp, &dt);

	if (dt.value != NULL) {
		zone = resolve_tzid (dt.tzid, ctx);
		if (zone)
			due_t = icaltime_as_timet_with_zone (*dt.value,zone);
		else
			due_t = icaltime_as_timet (*dt.value);
	}

	if (dt.value != NULL && (due_t <= end && due_t >= start))
		retval = TRUE;
	else
		retval = FALSE;

	result = e_sexp_result_new (esexp, ESEXP_RES_BOOL);
	result->value.boolean = retval;

	e_cal_component_free_datetime (&dt);

	return result;
}

/* Returns whether a list of ECalComponentText items matches the specified string */
static gboolean
matches_text_list (GSList *text_list,
                   const gchar *str)
{
	GSList *l;
	gboolean matches;

	matches = FALSE;

	for (l = text_list; l; l = l->next) {
		ECalComponentText *text;

		text = l->data;

		if (text && e_util_utf8_strstrcasedecomp (text->value, str) != NULL) {
			matches = TRUE;
			break;
		}
	}

	return matches;
}

/* Returns whether the comments in a component matches the specified string */
static gboolean
matches_comment (ECalComponent *comp,
                 const gchar *str)
{
	GSList *list;
	gboolean matches;

	e_cal_component_get_comment_list (comp, &list);
	matches = matches_text_list (list, str);
	e_cal_component_free_text_list (list);

	return matches;
}

/* Returns whether the description in a component matches the specified string */
static gboolean
matches_description (ECalComponent *comp,
                     const gchar *str)
{
	GSList *list;
	gboolean matches;

	e_cal_component_get_description_list (comp, &list);
	matches = matches_text_list (list, str);
	e_cal_component_free_text_list (list);

	return matches;
}

static gboolean
matches_attendee (ECalComponent *comp,
                  const gchar *str)
{
	GSList *a_list = NULL, *l;
	gboolean matches = FALSE;

	e_cal_component_get_attendee_list (comp, &a_list);

	for (l = a_list; l; l = l->next) {
		ECalComponentAttendee *att = l->data;

		if ((att->value && e_util_utf8_strstrcasedecomp (att->value, str)) ||
		    (att->cn != NULL && e_util_utf8_strstrcasedecomp (att->cn, str))) {
			matches = TRUE;
			break;
		}
	}

	e_cal_component_free_attendee_list (a_list);

	return matches;

}

static gboolean
matches_organizer (ECalComponent *comp,
                   const gchar *str)
{

	ECalComponentOrganizer org;

	e_cal_component_get_organizer (comp, &org);
	if (str && !*str)
		return TRUE;

	if ((org.value && e_util_utf8_strstrcasedecomp (org.value, str)) ||
	    (org.cn && e_util_utf8_strstrcasedecomp (org.cn, str)))
		return TRUE;

	return FALSE;
}

static gboolean
matches_classification (ECalComponent *comp,
                        const gchar *str)
{
	ECalComponentClassification classification;
	ECalComponentClassification classification1;

	if (!*str)
		return FALSE;

	if (g_str_equal (str, "Public"))
		classification1 = E_CAL_COMPONENT_CLASS_PUBLIC;
	else if (g_str_equal (str, "Private"))
		classification1 = E_CAL_COMPONENT_CLASS_PRIVATE;
	else if (g_str_equal (str, "Confidential"))
		classification1 = E_CAL_COMPONENT_CLASS_CONFIDENTIAL;
	else
		classification1 = E_CAL_COMPONENT_CLASS_UNKNOWN;

	e_cal_component_get_classification (comp, &classification);

	return (classification == classification1 ? TRUE : FALSE);
}

/* Returns whether the summary in a component matches the specified string */
static gboolean
matches_summary (ECalComponent *comp,
                 const gchar *str)
{
	ECalComponentText text;

	e_cal_component_get_summary (comp, &text);

	if (!*str)
		return TRUE;

	if (!text.value)
		return FALSE;

	return e_util_utf8_strstrcasedecomp (text.value, str) != NULL;
}

/* Returns whether the location in a component matches the specified string */
static gboolean
matches_location (ECalComponent *comp,
                  const gchar *str)
{
	const gchar *location = NULL;

	e_cal_component_get_location (comp, &location);

	if (!location)
		return FALSE;

	return e_util_utf8_strstrcasedecomp (location, str) != NULL;
}

/* Returns whether any text field in a component matches the specified string */
static gboolean
matches_any (ECalComponent *comp,
             const gchar *str)
{
	/* As an optimization, and to make life easier for the individual
	 * predicate functions, see if we are looking for the empty string right
	 * away.
	 */
	if (strlen (str) == 0)
		return TRUE;

	return (matches_comment (comp, str)
		|| matches_description (comp, str)
		|| matches_summary (comp, str)
		|| matches_location (comp, str));
}

static gboolean
matches_priority (ECalComponent *comp ,const gchar *pr)
{
	gboolean res = FALSE;
	gint *priority = NULL;

	e_cal_component_get_priority (comp, &priority);

	if (!priority)
		return g_str_equal (pr, "UNDEFINED");

	if (g_str_equal (pr, "HIGH") && *priority <= 4)
		res = TRUE;
	else if (g_str_equal (pr, "NORMAL") && *priority == 5)
		res = TRUE;
	else if (g_str_equal (pr, "LOW") && *priority > 5)
		res = TRUE;

	e_cal_component_free_priority (priority);

	return res;
}

static gboolean
matches_status (ECalComponent *comp ,const gchar *str)
{
	icalproperty_status status;

	if (!*str)
		return FALSE;

	e_cal_component_get_status (comp, &status);

	switch (status) {
	case ICAL_STATUS_NONE:
		return g_str_equal (str, "NOT STARTED");
	case ICAL_STATUS_COMPLETED:
		return g_str_equal (str, "COMPLETED");
	case ICAL_STATUS_CANCELLED:
		return g_str_equal (str, "CANCELLED");
	case ICAL_STATUS_INPROCESS:
		return g_str_equal (str, "IN PROGRESS");
	case ICAL_STATUS_NEEDSACTION:
		return g_str_equal (str, "NEEDS ACTION");
	case ICAL_STATUS_TENTATIVE:
		return g_str_equal (str, "TENTATIVE");
	case ICAL_STATUS_CONFIRMED:
		return g_str_equal (str, "CONFIRMED");
	case ICAL_STATUS_DRAFT:
		return g_str_equal (str, "DRAFT");
	case ICAL_STATUS_FINAL:
		return g_str_equal (str, "FINAL");
	case ICAL_STATUS_SUBMITTED:
		return g_str_equal (str, "SUBMITTED");
	case ICAL_STATUS_PENDING:
		return g_str_equal (str, "PENDING");
	case ICAL_STATUS_FAILED:
		return g_str_equal (str, "FAILED");
#ifdef HAVE_ICAL_STATUS_DELETED
	case ICAL_STATUS_DELETED:
		return g_str_equal (str, "DELETED");
#endif
	case ICAL_STATUS_X:
		break;
	}

	return FALSE;
}

static ESExpResult *
func_has_attachment (ESExp *esexp,
                     gint argc,
                     ESExpResult **argv,
                     gpointer data)
{
	SearchContext *ctx = data;
	ESExpResult *result;

	if (argc != 0) {
		e_sexp_fatal_error (
			esexp, _("“%s” expects no arguments"),
				"has-attachments?");
		return NULL;
	}

	result = e_sexp_result_new (esexp, ESEXP_RES_BOOL);
	result->value.boolean = e_cal_component_has_attachments (ctx->comp);

	return result;
}

static ESExpResult *
func_percent_complete (ESExp *esexp,
                       gint argc,
                       ESExpResult **argv,
                       gpointer data)
{
	SearchContext *ctx = data;
	ESExpResult *result = NULL;
	gint *percent;

	if (argc != 0) {
		e_sexp_fatal_error (
			esexp, _("“%s” expects no arguments"),
				"percent-completed");
		return NULL;
	}

	e_cal_component_get_percent (ctx->comp, &percent);

	result = e_sexp_result_new (esexp, ESEXP_RES_INT);

	if (percent) {
		result->value.number = *percent;
		e_cal_component_free_percent (percent);
	} else {
		result->value.number = -1;
	}

	return result;
}

/* (contains? FIELD STR)
 *
 * FIELD - string, name of field to match
 *         (any, comment, description, summary, location)
 * STR - string, match string
 *
 * Returns a boolean indicating whether the specified field contains the
 * specified string.
 */
static ESExpResult *
func_contains (ESExp *esexp,
               gint argc,
               ESExpResult **argv,
               gpointer data)
{
	SearchContext *ctx = data;
	const gchar *field;
	const gchar *str;
	gboolean matches;
	ESExpResult *result;

	/* Check argument types */

	if (argc != 2) {
		e_sexp_fatal_error (
			esexp, _("“%s” expects two arguments"),
			"contains");
		return NULL;
	}

	if (argv[0]->type != ESEXP_RES_STRING) {
		e_sexp_fatal_error (
			esexp, _("“%s” expects the first "
			"argument to be a string"),
			"contains");
		return NULL;
	}
	field = argv[0]->value.string;

	if (argv[1]->type != ESEXP_RES_STRING) {
		e_sexp_fatal_error (
			esexp, _("“%s” expects the second "
			"argument to be a string"),
			"contains");
		return NULL;
	}
	str = argv[1]->value.string;

	/* See if it matches */

	if (strcmp (field, "any") == 0)
		matches = matches_any (ctx->comp, str);
	else if (strcmp (field, "comment") == 0)
		matches = matches_comment (ctx->comp, str);
	else if (strcmp (field, "description") == 0)
		matches = matches_description (ctx->comp, str);
	else if (strcmp (field, "summary") == 0)
		matches = matches_summary (ctx->comp, str);
	else if (strcmp (field, "location") == 0)
		matches = matches_location (ctx->comp, str);
	else if (strcmp (field, "attendee") == 0)
		matches = matches_attendee (ctx->comp, str);
	else if (strcmp (field, "organizer") == 0)
		matches = matches_organizer (ctx->comp, str);
	else if (strcmp (field, "classification") == 0)
		matches = matches_classification (ctx->comp, str);
	else if (strcmp (field, "status") == 0)
		matches = matches_status (ctx->comp, str);
	else if (strcmp (field, "priority") == 0)
		matches = matches_priority (ctx->comp, str);
	else {
		e_sexp_fatal_error (
			esexp, _("“%s” expects the first "
			"argument to be either “any”, "
			"“summary”, or “description”, or "
			"“location”, or “attendee”, or "
			"“organizer”, or “classification”"),
			"contains");
		return NULL;
	}

	result = e_sexp_result_new (esexp, ESEXP_RES_BOOL);
	result->value.boolean = matches;

	return result;
}

/* (has-start?)
 *
 * A boolean value for components that have/don't have filled start date/time.
 *
 * Returns: whether the component has start date/time filled
 */
static ESExpResult *
func_has_start (ESExp *esexp,
                gint argc,
                ESExpResult **argv,
                gpointer data)
{
	SearchContext *ctx = data;
	ESExpResult *result;
	ECalComponentDateTime dt;

	/* Check argument types */

	if (argc != 0) {
		e_sexp_fatal_error (
			esexp, _("“%s” expects no arguments"),
			"has-start");
		return NULL;
	}

	e_cal_component_get_dtstart (ctx->comp, &dt);
	result = e_sexp_result_new (esexp, ESEXP_RES_BOOL);
	result->value.boolean = dt.value != NULL;
	e_cal_component_free_datetime (&dt);

	return result;
}

/* (has-alarms?)
 *
 * A boolean value for components that have/dont have alarms.
 *
 * Returns: a boolean indicating whether the component has alarms or not.
 */
static ESExpResult *
func_has_alarms (ESExp *esexp,
                 gint argc,
                 ESExpResult **argv,
                 gpointer data)
{
	SearchContext *ctx = data;
	ESExpResult *result;

	/* Check argument types */

	if (argc != 0) {
		e_sexp_fatal_error (
			esexp, _("“%s” expects no arguments"),
			"has-alarms");
		return NULL;
	}

	result = e_sexp_result_new (esexp, ESEXP_RES_BOOL);
	result->value.boolean = e_cal_component_has_alarms (ctx->comp);

	return result;
}

/* (has-alarms-in-range? START END)
 *
 * START - time_t, start of the time range
 * END - time_t, end of the time range
 *
 * Returns: a boolean indicating whether the component has alarms in the given
 * time range or not.
 */
static ESExpResult *
func_has_alarms_in_range (ESExp *esexp,
                          gint argc,
                          ESExpResult **argv,
                          gpointer data)
{
	time_t start, end;
	ESExpResult *result;
	icaltimezone *default_zone;
	ECalComponentAlarms *alarms;
	ECalComponentAlarmAction omit[] = {-1};
	SearchContext *ctx = data;

	/* Check argument types */

	if (argc != 2) {
		e_sexp_fatal_error (
			esexp, _("“%s” expects two arguments"),
			"has-alarms-in-range");
		return NULL;
	}

	if (argv[0]->type != ESEXP_RES_TIME) {
		e_sexp_fatal_error (
			esexp, _("“%s” expects the first "
			"argument to be a time_t"),
			"has-alarms-in-range");
		return NULL;
	}
	start = argv[0]->value.time;

	if (argv[1]->type != ESEXP_RES_TIME) {
		e_sexp_fatal_error (
			esexp, _("“%s” expects the second "
			"argument to be a time_t"),
			"has-alarms-in-range");
		return NULL;
	}
	end = argv[1]->value.time;

	/* See if the object has alarms in the given time range */
	default_zone = icaltimezone_get_utc_timezone ();

	alarms = e_cal_util_generate_alarms_for_comp (
		ctx->comp, start, end,
		omit, resolve_tzid,
		ctx, default_zone);

	result = e_sexp_result_new (esexp, ESEXP_RES_BOOL);
	if (alarms) {
		result->value.boolean = TRUE;
		e_cal_component_alarms_free (alarms);
	} else
		result->value.boolean = FALSE;

	return result;
}

/* (has-categories? STR+)
 * (has-categories? #f)
 *
 * STR - At least one string specifying a category
 * Or you can specify a single #f (boolean false) value for components
 * that have no categories assigned to them ("unfiled").
 *
 * Returns a boolean indicating whether the component has all the specified
 * categories.
 */
static ESExpResult *
func_has_categories (ESExp *esexp,
                     gint argc,
                     ESExpResult **argv,
                     gpointer data)
{
	SearchContext *ctx = data;
	gboolean unfiled;
	gint i;
	GSList *categories;
	gboolean matches;
	ESExpResult *result;

	/* Check argument types */

	if (argc < 1) {
		e_sexp_fatal_error (
			esexp, _("“%s” expects at least one "
			"argument"),
			"has-categories");
		return NULL;
	}

	if (argc == 1 && argv[0]->type == ESEXP_RES_BOOL)
		unfiled = TRUE;
	else
		unfiled = FALSE;

	if (!unfiled)
		for (i = 0; i < argc; i++)
			if (argv[i]->type != ESEXP_RES_STRING) {
				e_sexp_fatal_error (
					esexp, _("“%s” expects "
					"all arguments to "
					"be strings or "
					"one and only one "
					"argument to be a "
					"boolean false "
					"(#f)"),
					"has-categories");
				return NULL;
			}

	/* Search categories.  First, if there are no categories we return
	 * whether unfiled components are supposed to match.
	 */

	e_cal_component_get_categories_list (ctx->comp, &categories);
	if (!categories) {
		result = e_sexp_result_new (esexp, ESEXP_RES_BOOL);
		result->value.boolean = unfiled;

		return result;
	}

	/* Otherwise, we *do* have categories but unfiled components were
	 * requested, so this component does not match.
	 */
	if (unfiled) {
		result = e_sexp_result_new (esexp, ESEXP_RES_BOOL);
		result->value.boolean = FALSE;

		e_cal_component_free_categories_list (categories);

		return result;
	}

	matches = TRUE;

	for (i = 0; i < argc; i++) {
		const gchar *sought;
		GSList *l;
		gboolean has_category;

		sought = argv[i]->value.string;

		has_category = FALSE;

		for (l = categories; l; l = l->next) {
			const gchar *category;

			category = l->data;

			if (strcmp (category, sought) == 0) {
				has_category = TRUE;
				break;
			}
		}

		if (!has_category) {
			matches = FALSE;
			break;
		}
	}

	e_cal_component_free_categories_list (categories);

	result = e_sexp_result_new (esexp, ESEXP_RES_BOOL);
	result->value.boolean = matches;

	return result;
}

/* (has-recurrences?)
 *
 * A boolean value for components that have/dont have recurrences.
 *
 * Returns: a boolean indicating whether the component has recurrences or not.
 */
static ESExpResult *
func_has_recurrences (ESExp *esexp,
                      gint argc,
                      ESExpResult **argv,
                      gpointer data)
{
	SearchContext *ctx = data;
	ESExpResult *result;

	/* Check argument types */

	if (argc != 0) {
		e_sexp_fatal_error (
			esexp, _("“%s” expects no arguments"),
			"has-recurrences");
		return NULL;
	}

	result = e_sexp_result_new (esexp, ESEXP_RES_BOOL);
	result->value.boolean =
		e_cal_component_has_recurrences (ctx->comp) ||
		e_cal_component_is_instance (ctx->comp);

	return result;
}

/* (is-completed?)
 *
 * Returns a boolean indicating whether the component is completed (i.e. has
 * a COMPLETED property. This is really only useful for TODO components.
 */
static ESExpResult *
func_is_completed (ESExp *esexp,
                   gint argc,
                   ESExpResult **argv,
                   gpointer data)
{
	SearchContext *ctx = data;
	ESExpResult *result;
	struct icaltimetype *t;
	gboolean complete = FALSE;

	/* Check argument types */

	if (argc != 0) {
		e_sexp_fatal_error (
			esexp, _("“%s” expects no arguments"),
			"is-completed");
		return NULL;
	}

	e_cal_component_get_completed (ctx->comp, &t);
	if (t) {
		complete = TRUE;
		e_cal_component_free_icaltimetype (t);
	} else {
		icalproperty_status status = ICAL_STATUS_NONE;

		e_cal_component_get_status (ctx->comp, &status);

		complete = status == ICAL_STATUS_COMPLETED;
	}

	result = e_sexp_result_new (esexp, ESEXP_RES_BOOL);
	result->value.boolean = complete;

	return result;
}

/* (completed-before? TIME)
 *
 * TIME - time_t
 *
 * Returns a boolean indicating whether the component was completed on or
 * before the given time (i.e. it checks the COMPLETED property).
 * This is really only useful for TODO components.
 */
static ESExpResult *
func_completed_before (ESExp *esexp,
                       gint argc,
                       ESExpResult **argv,
                       gpointer data)
{
	SearchContext *ctx = data;
	ESExpResult *result;
	struct icaltimetype *tt;
	icaltimezone *zone;
	gboolean retval = FALSE;
	time_t before_time, completed_time;

	/* Check argument types */

	if (argc != 1) {
		e_sexp_fatal_error (
			esexp, _("“%s” expects one argument"),
			"completed-before");
		return NULL;
	}

	if (argv[0]->type != ESEXP_RES_TIME) {
		e_sexp_fatal_error (
			esexp, _("“%s” expects the first "
			"argument to be a time_t"),
			"completed-before");
		return NULL;
	}
	before_time = argv[0]->value.time;

	e_cal_component_get_completed (ctx->comp, &tt);
	if (tt) {
		/* COMPLETED must be in UTC. */
		zone = icaltimezone_get_utc_timezone ();
		completed_time = icaltime_as_timet_with_zone (*tt, zone);

		/* We want to return TRUE if before_time is after
		 * completed_time. */
		if (difftime (before_time, completed_time) > 0) {
			retval = TRUE;
		}

		e_cal_component_free_icaltimetype (tt);
	}

	result = e_sexp_result_new (esexp, ESEXP_RES_BOOL);
	result->value.boolean = retval;

	return result;
}

static void
cal_backend_sexp_finalize (GObject *object)
{
	ECalBackendSExpPrivate *priv;

	priv = E_CAL_BACKEND_SEXP_GET_PRIVATE (object);

	g_object_unref (priv->search_sexp);
	g_free (priv->text);
	g_free (priv->search_context);
	g_mutex_clear (&priv->search_context_lock);

	/* Chain up to parent's finalize() method. */
	G_OBJECT_CLASS (e_cal_backend_sexp_parent_class)->finalize (object);
}

static void
e_cal_backend_sexp_class_init (ECalBackendSExpClass *class)
{
	GObjectClass *object_class;

	g_type_class_add_private (class, sizeof (ECalBackendSExpPrivate));

	object_class = G_OBJECT_CLASS (class);
	object_class->finalize = cal_backend_sexp_finalize;
}

static void
e_cal_backend_sexp_init (ECalBackendSExp *sexp)
{
	sexp->priv = E_CAL_BACKEND_SEXP_GET_PRIVATE (sexp);
	sexp->priv->search_context = g_new (SearchContext, 1);

	g_mutex_init (&sexp->priv->search_context_lock);
}

/* 'builtin' functions */
static struct {
	const gchar *name;
	ESExpFunc *func;
	gint type;	/* set to 1 if a function can perform shortcut
			 * evaluation, or doesn't execute everything,
			 * 0 otherwise */
} symbols[] = {
	/* Time-related functions */
	{ "time-now", e_cal_backend_sexp_func_time_now, 0 },
	{ "make-time", e_cal_backend_sexp_func_make_time, 0 },
	{ "time-add-day", e_cal_backend_sexp_func_time_add_day, 0 },
	{ "time-day-begin", e_cal_backend_sexp_func_time_day_begin, 0 },
	{ "time-day-end", e_cal_backend_sexp_func_time_day_end, 0 },
	/* Component-related functions */
	{ "uid?", func_uid, 0 },
	{ "occur-in-time-range?", func_occur_in_time_range, 0 },
	{ "due-in-time-range?", func_due_in_time_range, 0 },
	{ "contains?", func_contains, 0 },
	{ "has-start?", func_has_start, 0 },
	{ "has-alarms?", func_has_alarms, 0 },
	{ "has-alarms-in-range?", func_has_alarms_in_range, 0 },
	{ "has-recurrences?", func_has_recurrences, 0 },
	{ "has-categories?", func_has_categories, 0 },
	{ "is-completed?", func_is_completed, 0 },
	{ "completed-before?", func_completed_before, 0 },
	{ "has-attachments?", func_has_attachment, 0 },
	{ "percent-complete?", func_percent_complete, 0 },
	{ "occurrences-count?", func_occurrences_count, 0 }
};

/**
 * e_cal_backend_card_sexp_new:
 * @text: The expression to use.
 *
 * Creates a new #ECalBackendSExp from @text.
 *
 * Returns: a new #ECalBackendSExp
 */
ECalBackendSExp *
e_cal_backend_sexp_new (const gchar *text)
{
	ECalBackendSExp *sexp;
	gint ii;

	g_return_val_if_fail (text != NULL, NULL);

	sexp = g_object_new (E_TYPE_CAL_BACKEND_SEXP, NULL);
	sexp->priv->search_sexp = e_sexp_new ();
	sexp->priv->text = g_strdup (text);

	for (ii = 0; ii < G_N_ELEMENTS (symbols); ii++) {
		if (symbols[ii].type == 1) {
			e_sexp_add_ifunction (
				sexp->priv->search_sexp, 0,
				symbols[ii].name,
				(ESExpIFunc *) symbols[ii].func,
				sexp->priv->search_context);
		} else {
			e_sexp_add_function (
				sexp->priv->search_sexp, 0,
				symbols[ii].name,
				symbols[ii].func,
				sexp->priv->search_context);
		}
	}

	e_sexp_input_text (sexp->priv->search_sexp, text, strlen (text));

	if (e_sexp_parse (sexp->priv->search_sexp) == -1) {
		g_object_unref (sexp);
		sexp = NULL;
	}

	if (sexp != NULL) {
		SearchContext *ctx = sexp->priv->search_context;

		ctx->expr_range_set = e_sexp_evaluate_occur_times (
			sexp->priv->search_sexp,
			&ctx->expr_range_start,
			&ctx->expr_range_end);
	}

	return sexp;
}

/**
 * e_cal_backend_sexp_text:
 * @sexp: An #ECalBackendSExp object.
 *
 * Retrieve the text expression for the given #ECalBackendSExp object.
 *
 * Returns: the text expression
 */
const gchar *
e_cal_backend_sexp_text (ECalBackendSExp *sexp)
{
	g_return_val_if_fail (E_IS_CAL_BACKEND_SEXP (sexp), NULL);

	return sexp->priv->text;
}

/**
 * e_cal_backend_sexp_match_comp:
 * @sexp: An #ESExp object.
 * @comp: Component to match against the expression.
 * @cache: an #ETimezoneCache
 *
 * Checks if @comp matches @sexp.
 *
 * Returns: %TRUE if the component matches, %FALSE otherwise
 */
gboolean
e_cal_backend_sexp_match_comp (ECalBackendSExp *sexp,
                               ECalComponent *comp,
                               ETimezoneCache *cache)
{
	ESExpResult *r;
	gboolean retval;

	g_return_val_if_fail (E_IS_CAL_BACKEND_SEXP (sexp), FALSE);
	g_return_val_if_fail (E_IS_CAL_COMPONENT (comp), FALSE);
	g_return_val_if_fail (E_IS_TIMEZONE_CACHE (cache), FALSE);

	g_mutex_lock (&sexp->priv->search_context_lock);

	sexp->priv->search_context->comp = g_object_ref (comp);
	sexp->priv->search_context->cache = g_object_ref (cache);

	r = e_sexp_eval (sexp->priv->search_sexp);

	retval = (r && r->type == ESEXP_RES_BOOL && r->value.boolean);

	g_object_unref (sexp->priv->search_context->comp);
	g_object_unref (sexp->priv->search_context->cache);

	e_sexp_result_free (sexp->priv->search_sexp, r);

	g_mutex_unlock (&sexp->priv->search_context_lock);

	return retval;
}

/**
 * e_cal_backend_sexp_match_object:
 * @sexp: An #ESExp object.
 * @object: An iCalendar string.
 * @cache: an #ETimezoneCache
 *
 * Checks if @object matches @sexp.
 *
 * Returns: %TRUE if the object matches, %FALSE otherwise
 */
gboolean
e_cal_backend_sexp_match_object (ECalBackendSExp *sexp,
                                 const gchar *object,
                                 ETimezoneCache *cache)
{
	ECalComponent *comp;
	icalcomponent *icalcomp;
	gboolean retval;

	g_return_val_if_fail (E_IS_CAL_BACKEND_SEXP (sexp), FALSE);
	g_return_val_if_fail (object != NULL, FALSE);
	g_return_val_if_fail (E_IS_TIMEZONE_CACHE (cache), FALSE);

	icalcomp = icalcomponent_new_from_string ((gchar *) object);
	if (!icalcomp)
		return FALSE;

	comp = e_cal_component_new ();
	e_cal_component_set_icalcomponent (comp, icalcomp);

	retval = e_cal_backend_sexp_match_comp (sexp, comp, cache);

	g_object_unref (comp);

	return retval;
}

/**
 * e_cal_backend_sexp_func_time_now:
 * @esexp: An #ESExp object.
 * @argc: Number of arguments.
 * @argv: The arguments.
 * @data: Closure data.
 *
 * Processes the (time-now) sexp expression.
 *
 * Returns: The result of the function.
 */
ESExpResult *
e_cal_backend_sexp_func_time_now (ESExp *esexp,
                                  gint argc,
                                  ESExpResult **argv,
                                  gpointer data)
{
	ESExpResult *result;

	g_return_val_if_fail (esexp != NULL, NULL);

	if (argc != 0) {
		e_sexp_fatal_error (
			esexp, _("“%s” expects no arguments"),
			"time-now");
		return NULL;
	}

	result = e_sexp_result_new (esexp, ESEXP_RES_TIME);
	result->value.time = time (NULL);

	return result;
}

/**
 * e_cal_backend_sexp_func_make_time:
 * @esexp: An #ESExp object.
 * @argc: Number of arguments.
 * @argv: The arguments.
 * @data: Closure data.
 *
 * (make-time ISODATE)
 * ISODATE - string, ISO 8601 date/time representation
 *
 * Constructs a time_t value for the specified date.
 *
 * Returns: The result of the function.
 */
ESExpResult *
e_cal_backend_sexp_func_make_time (ESExp *esexp,
                                   gint argc,
                                   ESExpResult **argv,
                                   gpointer data)
{
	const gchar *str;
	time_t t;
	ESExpResult *result;

	g_return_val_if_fail (esexp != NULL, NULL);

	if (argc != 1) {
		e_sexp_fatal_error (
			esexp, _("“%s” expects one argument"),
			"make-time");
		return NULL;
	}

	if (argv[0]->type != ESEXP_RES_STRING) {
		e_sexp_fatal_error (
			esexp, _("“%s” expects the first "
			"argument to be a string"),
			"make-time");
		return NULL;
	}
	str = argv[0]->value.string;
	if (!str || !*str) {
		e_sexp_fatal_error (
			esexp, _("“%s” expects the first "
			"argument to be a string"),
			"make-time");
		return NULL;
	}

	t = time_from_isodate (str);
	if (t == -1) {
		e_sexp_fatal_error (
			esexp, _("“%s” expects the first "
			"argument to be an ISO 8601 "
			"date/time string"),
			"make-time");
		return NULL;
	}

	result = e_sexp_result_new (esexp, ESEXP_RES_TIME);
	result->value.time = t;

	return result;
}

/**
 * e_cal_backend_sexp_func_time_add_day:
 * @esexp: An #ESExp object.
 * @argc: Number of arguments.
 * @argv: The arguments.
 * @data: Closure data.
 *
 * (time-add-day TIME N)
 * TIME - time_t, base time
 * N - int, number of days to add
 *
 * Adds the specified number of days to a time value.
 *
 * FIXME: TIMEZONES - need to use a timezone or daylight saving changes will
 * make the result incorrect.
 *
 * Returns: The result of the function.
 */
ESExpResult *
e_cal_backend_sexp_func_time_add_day (ESExp *esexp,
                                      gint argc,
                                      ESExpResult **argv,
                                      gpointer data)
{
	ESExpResult *result;
	time_t t;
	gint n;

	g_return_val_if_fail (esexp != NULL, NULL);

	if (argc != 2) {
		e_sexp_fatal_error (
			esexp, _("“%s” expects two arguments"),
			"time-add-day");
		return NULL;
	}

	if (argv[0]->type != ESEXP_RES_TIME) {
		e_sexp_fatal_error (
			esexp, _("“%s” expects the first "
			"argument to be a time_t"),
			"time-add-day");
		return NULL;
	}
	t = argv[0]->value.time;

	if (argv[1]->type != ESEXP_RES_INT) {
		e_sexp_fatal_error (
			esexp, _("“%s” expects the second "
			"argument to be an integer"),
			"time-add-day");
		return NULL;
	}
	n = argv[1]->value.number;

	result = e_sexp_result_new (esexp, ESEXP_RES_TIME);
	result->value.time = time_add_day (t, n);

	return result;
}

/**
 * e_cal_backend_sexp_func_time_day_begin:
 * @esexp: An #ESExp object.
 * @argc: Number of arguments.
 * @argv: The arguments.
 * @data: Closure data.
 *
 * (time-day-begin TIME)
 * TIME - time_t, base time
 *
 * Returns the start of the day, according to the local time.
 *
 * FIXME: TIMEZONES - this uses the current Unix timezone.
 *
 * Returns: The result of the function.
 */
ESExpResult *
e_cal_backend_sexp_func_time_day_begin (ESExp *esexp,
                                        gint argc,
                                        ESExpResult **argv,
                                        gpointer data)
{
	time_t t;
	ESExpResult *result;

	g_return_val_if_fail (esexp != NULL, NULL);

	if (argc != 1) {
		e_sexp_fatal_error (
			esexp, _("“%s” expects one argument"),
			"time-day-begin");
		return NULL;
	}

	if (argv[0]->type != ESEXP_RES_TIME) {
		e_sexp_fatal_error (
			esexp, _("“%s” expects the first "
			"argument to be a time_t"),
			"time-day-begin");
		return NULL;
	}
	t = argv[0]->value.time;

	result = e_sexp_result_new (esexp, ESEXP_RES_TIME);
	result->value.time = time_day_begin (t);

	return result;
}

/**
 * e_cal_backend_sexp_func_time_day_end:
 * @esexp: An #ESExp object.
 * @argc: Number of arguments.
 * @argv: The arguments.
 * @data: Closure data.
 *
 * (time-day-end TIME)
 * TIME - time_t, base time
 *
 * Returns the end of the day, according to the local time.
 *
 * FIXME: TIMEZONES - this uses the current Unix timezone.
 *
 * Returns: The result of the function.
 */
ESExpResult *
e_cal_backend_sexp_func_time_day_end (ESExp *esexp,
                                      gint argc,
                                      ESExpResult **argv,
                                      gpointer data)
{
	time_t t;
	ESExpResult *result;

	g_return_val_if_fail (esexp != NULL, NULL);

	if (argc != 1) {
		e_sexp_fatal_error (
			esexp, _("“%s” expects one argument"),
			"time-day-end");
		return NULL;
	}

	if (argv[0]->type != ESEXP_RES_TIME) {
		e_sexp_fatal_error (
			esexp, _("“%s” expects the first "
			"argument to be a time_t"),
			"time-day-end");
		return NULL;
	}
	t = argv[0]->value.time;

	result = e_sexp_result_new (esexp, ESEXP_RES_TIME);
	result->value.time = time_day_end (t);

	return result;
}

/**
 * e_cal_backend_sexp_evaluate_occur_times:
 * @sexp: An #ESExp object.
 * @start: Start of the time window will be stored here.
 * @end: End of the time window will be stored here.
 *
 * Determines biggest time window given by expressions "occur-in-range" in sexp.
 *
 * Returns: %TRUE on success, %FALSE otherwise
 *
 * Since: 2.32
 */
gboolean
e_cal_backend_sexp_evaluate_occur_times (ECalBackendSExp *sexp,
                                         time_t *start,
                                         time_t *end)
{
	g_return_val_if_fail (E_IS_CAL_BACKEND_SEXP (sexp), FALSE);
	g_return_val_if_fail (start != NULL, FALSE);
	g_return_val_if_fail (end != NULL, FALSE);

	if (!sexp->priv->search_context->expr_range_set)
		return FALSE;

	*start = sexp->priv->search_context->expr_range_start;
	*end = sexp->priv->search_context->expr_range_end;

	return TRUE;
}

