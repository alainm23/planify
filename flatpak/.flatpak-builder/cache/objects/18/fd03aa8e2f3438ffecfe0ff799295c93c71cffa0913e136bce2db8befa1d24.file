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
 * Authors: Jeffrey Stedfast <fejj@ximian.com>
 *	    Michael Zucchi <NotZed@Ximian.com>
 */

#include "evolution-data-server-config.h"

/* POSIX requires <sys/types.h> be included before <regex.h> */
#include <sys/types.h>

#include <ctype.h>
#include <errno.h>
#include <fcntl.h>
#include <regex.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

#include <glib/gi18n-lib.h>

#ifndef G_OS_WIN32
#include <sys/wait.h>
#endif

#include "camel-debug.h"
#include "camel-filter-search.h"
#include "camel-iconv.h"
#include "camel-mime-message.h"
#include "camel-multipart.h"
#include "camel-provider.h"
#include "camel-search-private.h"
#include "camel-session.h"
#include "camel-stream-fs.h"
#include "camel-stream-mem.h"
#include "camel-string-utils.h"
#include "camel-url.h"

#define d(x)

typedef struct {
	CamelSession *session;
	CamelFilterSearchGetMessageFunc get_message;
	gpointer get_message_data;
	CamelMimeMessage *message;
	CamelMessageInfo *info;
	CamelFolder *folder;
	const gchar *source;
	FILE *logfile;
	GCancellable *cancellable;
	GError **error;
} FilterMessageSearch;

/* CamelSExp callbacks */
static CamelSExpResult *header_contains (struct _CamelSExp *f, gint argc, struct _CamelSExpResult **argv, FilterMessageSearch *fms);
static CamelSExpResult *header_has_words (struct _CamelSExp *f, gint argc, struct _CamelSExpResult **argv, FilterMessageSearch *fms);
static CamelSExpResult *header_matches (struct _CamelSExp *f, gint argc, struct _CamelSExpResult **argv, FilterMessageSearch *fms);
static CamelSExpResult *header_starts_with (struct _CamelSExp *f, gint argc, struct _CamelSExpResult **argv, FilterMessageSearch *fms);
static CamelSExpResult *header_ends_with (struct _CamelSExp *f, gint argc, struct _CamelSExpResult **argv, FilterMessageSearch *fms);
static CamelSExpResult *header_exists (struct _CamelSExp *f, gint argc, struct _CamelSExpResult **argv, FilterMessageSearch *fms);
static CamelSExpResult *header_soundex (struct _CamelSExp *f, gint argc, struct _CamelSExpResult **argv, FilterMessageSearch *fms);
static CamelSExpResult *header_regex (struct _CamelSExp *f, gint argc, struct _CamelSExpResult **argv, FilterMessageSearch *fms);
static CamelSExpResult *header_full_regex (struct _CamelSExp *f, gint argc, struct _CamelSExpResult **argv, FilterMessageSearch *fms);
static CamelSExpResult *match_all (struct _CamelSExp *f, gint argc, struct _CamelSExpTerm **argv, FilterMessageSearch *fms);
static CamelSExpResult *body_contains (struct _CamelSExp *f, gint argc, struct _CamelSExpResult **argv, FilterMessageSearch *fms);
static CamelSExpResult *body_regex (struct _CamelSExp *f, gint argc, struct _CamelSExpResult **argv, FilterMessageSearch *fms);
static CamelSExpResult *user_flag (struct _CamelSExp *f, gint argc, struct _CamelSExpResult **argv, FilterMessageSearch *fms);
static CamelSExpResult *user_tag (struct _CamelSExp *f, gint argc, struct _CamelSExpResult **argv, FilterMessageSearch *fms);
static CamelSExpResult *system_flag (struct _CamelSExp *f, gint argc, struct _CamelSExpResult **argv, FilterMessageSearch *fms);
static CamelSExpResult *get_sent_date (struct _CamelSExp *f, gint argc, struct _CamelSExpResult **argv, FilterMessageSearch *fms);
static CamelSExpResult *get_received_date (struct _CamelSExp *f, gint argc, struct _CamelSExpResult **argv, FilterMessageSearch *fms);
static CamelSExpResult *get_current_date (struct _CamelSExp *f, gint argc, struct _CamelSExpResult **argv, FilterMessageSearch *fms);
static CamelSExpResult *get_relative_months (struct _CamelSExp *f, gint argc, struct _CamelSExpResult **argv, FilterMessageSearch *fms);
static CamelSExpResult *header_source (struct _CamelSExp *f, gint argc, struct _CamelSExpResult **argv, FilterMessageSearch *fms);
static CamelSExpResult *get_size (struct _CamelSExp *f, gint argc, struct _CamelSExpResult **argv, FilterMessageSearch *fms);
static CamelSExpResult *pipe_message (struct _CamelSExp *f, gint argc, struct _CamelSExpResult **argv, FilterMessageSearch *fms);
static CamelSExpResult *junk_test (struct _CamelSExp *f, gint argc, struct _CamelSExpResult **argv, FilterMessageSearch *fms);
static CamelSExpResult *message_location (struct _CamelSExp *f, gint argc, struct _CamelSExpResult **argv, FilterMessageSearch *fms);
static CamelSExpResult *make_time_func (struct _CamelSExp *f, gint argc, struct _CamelSExpResult **argv, FilterMessageSearch *fms);
static CamelSExpResult *compare_date_func (struct _CamelSExp *f, gint argc, struct _CamelSExpResult **argv, FilterMessageSearch *fms);

/* builtin functions */
static struct {
	const gchar *name;
	CamelSExpFunc func;
	gint type;		/* set to 1 if a function can perform shortcut evaluation, or
				   doesn't execute everything, 0 otherwise */
} symbols[] = {
	{ "match-all",          (CamelSExpFunc) match_all,          1 },
	{ "body-contains",      (CamelSExpFunc) body_contains,      0 },
	{ "body-regex",         (CamelSExpFunc) body_regex,         0 },
	{ "header-contains",    (CamelSExpFunc) header_contains,    0 },
	{ "header-has-words",   (CamelSExpFunc) header_has_words,   0 },
	{ "header-matches",     (CamelSExpFunc) header_matches,     0 },
	{ "header-starts-with", (CamelSExpFunc) header_starts_with, 0 },
	{ "header-ends-with",   (CamelSExpFunc) header_ends_with,   0 },
	{ "header-exists",      (CamelSExpFunc) header_exists,      0 },
	{ "header-soundex",     (CamelSExpFunc) header_soundex,     0 },
	{ "header-regex",       (CamelSExpFunc) header_regex,       0 },
	{ "header-full-regex",  (CamelSExpFunc) header_full_regex,  0 },
	{ "user-tag",           (CamelSExpFunc) user_tag,           0 },
	{ "user-flag",          (CamelSExpFunc) user_flag,          0 },
	{ "system-flag",        (CamelSExpFunc) system_flag,        0 },
	{ "get-sent-date",      (CamelSExpFunc) get_sent_date,      0 },
	{ "get-received-date",  (CamelSExpFunc) get_received_date,  0 },
	{ "get-current-date",   (CamelSExpFunc) get_current_date,   0 },
	{ "get-relative-months",(CamelSExpFunc) get_relative_months,0 },
	{ "header-source",      (CamelSExpFunc) header_source,      0 },
	{ "get-size",           (CamelSExpFunc) get_size,           0 },
	{ "pipe-message",       (CamelSExpFunc) pipe_message,       0 },
	{ "junk-test",          (CamelSExpFunc) junk_test,          0 },
	{ "message-location",   (CamelSExpFunc) message_location,   0 },
	{ "make-time",          (CamelSExpFunc) make_time_func,     0 },
	{ "compare-date",       (CamelSExpFunc) compare_date_func,  0 }
};

static void
camel_filter_search_log (FilterMessageSearch *fms,
			 const gchar *format,
			 ...) G_GNUC_PRINTF (2, 3);

static void
camel_filter_search_log (FilterMessageSearch *fms,
			 const gchar *format,
			 ...)
{
	gchar *str;
	va_list ap;

	if (!fms || !fms->logfile || !format)
		return;

	va_start (ap, format);
	str = g_strdup_vprintf (format, ap);
	va_end (ap);

	fprintf (fms->logfile, "   %s\n", str);
	fflush (fms->logfile);

	g_free (str);
}

static CamelMimeMessage *
camel_filter_search_get_message (FilterMessageSearch *fms,
                                 struct _CamelSExp *sexp)
{
	GError *local_error = NULL;

	if (fms->message)
		return fms->message;

	fms->message = fms->get_message (fms->get_message_data, fms->cancellable, &local_error);

	if (fms->message == NULL) {
		camel_filter_search_log (fms, "Failed to retrieve message: %s", local_error ? local_error->message : "Unknown error");
		camel_sexp_fatal_error (sexp, _("Failed to retrieve message"));
	}

	if (local_error)
		g_propagate_error (fms->error, local_error);

	return fms->message;
}

static const gchar *
camel_filter_search_get_header (FilterMessageSearch *fms,
				struct _CamelSExp *sexp,
				const gchar *name)
{
	const CamelNameValueArray *headers;
	CamelMimeMessage *message;
	const gchar *value;

	g_return_val_if_fail (fms != NULL, NULL);
	g_return_val_if_fail (name != NULL, NULL);

	headers = fms->info ? camel_message_info_get_headers (fms->info) : NULL;

	if (headers) {
		value = camel_name_value_array_get_named (headers, CAMEL_COMPARE_CASE_INSENSITIVE, name);

		while (value && g_ascii_isspace (*value))
			value++;

		return value;
	}

	message = camel_filter_search_get_message (fms, sexp);
	if (!message)
		return NULL;

	return camel_medium_get_header (CAMEL_MEDIUM (message), name);
}

static const CamelNameValueArray *
camel_filter_search_get_headers (FilterMessageSearch *fms,
				 struct _CamelSExp *sexp)
{
	const CamelNameValueArray *headers;

	g_return_val_if_fail (fms != NULL, NULL);

	headers = fms->info ? camel_message_info_get_headers (fms->info) : NULL;

	if (!headers) {
		CamelMimeMessage *message;

		message = camel_filter_search_get_message (fms, sexp);
		if (message)
			headers = camel_medium_get_headers (CAMEL_MEDIUM (message));
	}

	return headers;
}

static gboolean
check_header_in_message_info (FilterMessageSearch *fms,
                              gint argc,
                              struct _CamelSExpResult **argv,
                              camel_search_match_t how,
                              gboolean *matched)
{
	struct _KnownHeaders {
		const gchar *header_name;
		const gchar *info_name;
		camel_search_t type;
	} known_headers[] = {
		{ "Subject", "subject", CAMEL_SEARCH_TYPE_ENCODED },
		{ "From", "from", CAMEL_SEARCH_TYPE_ADDRESS_ENCODED },
		{ "To", "to", CAMEL_SEARCH_TYPE_ADDRESS_ENCODED },
		{ "Cc", "cc", CAMEL_SEARCH_TYPE_ADDRESS_ENCODED }
	};
	CamelMessageInfo *info;
	const gchar *name;
	gchar *value;
	gboolean found = FALSE;
	camel_search_t use_type;
	gint ii;

	g_return_val_if_fail (fms != NULL, FALSE);
	g_return_val_if_fail (argc > 1, FALSE);
	g_return_val_if_fail (argv != NULL, FALSE);
	g_return_val_if_fail (matched != NULL, FALSE);

	info = fms->info;

	/* If there are headers available, then prefer them, thus the addresses are used
	   as received, not as they are stored in the folder summary. */
	if (!info || camel_message_info_get_headers (info))
		return FALSE;

	name = argv[0]->value.string;
	g_return_val_if_fail (name != NULL, FALSE);

	/* test against any header */
	if (!*name) {
		gint jj;

		for (jj = 0; jj < G_N_ELEMENTS (known_headers); jj++) {
			value = NULL;

			g_object_get (G_OBJECT (info), known_headers[jj].info_name, &value, NULL);

			if (!value)
				continue;

			for (ii = 1; ii < argc && !*matched; ii++) {
				if (argv[ii]->type == CAMEL_SEXP_RES_STRING) {
					*matched = camel_search_header_match (value, argv[ii]->value.string, how, known_headers[jj].type, NULL);
					camel_filter_search_log (fms, "Info value '%s' of header '%s' does %smatch '%s'",
						value, known_headers[jj].header_name, *matched ? "" : "not ", argv[ii]->value.string);
				}
			}

			g_free (value);

			if (*matched)
				return TRUE;
		}

		return FALSE;
	}

	value = NULL;

	for (ii = 0; ii < G_N_ELEMENTS (known_headers); ii++) {
		found = g_ascii_strcasecmp (name, known_headers[ii].header_name) == 0;
		if (found) {
			g_object_get (G_OBJECT (info), known_headers[ii].info_name, &value, NULL);
			use_type = known_headers[ii].type;
			break;
		}
	}

	if (!found || !value) {
		g_free (value);
		return FALSE;
	}

	for (ii = 1; ii < argc && !*matched; ii++) {
		if (argv[ii]->type == CAMEL_SEXP_RES_STRING) {
			*matched = camel_search_header_match (value, argv[ii]->value.string, how, use_type, NULL);
			camel_filter_search_log (fms, "Info value '%s' of header '%s' does %smatch '%s'",
				value, name, *matched ? "" : "not ", argv[ii]->value.string);
		}
	}

	g_free (value);

	return TRUE;
}

static CamelSExpResult *
check_header (struct _CamelSExp *f,
              gint argc,
              struct _CamelSExpResult **argv,
              FilterMessageSearch *fms,
              camel_search_match_t how)
{
	gboolean matched = FALSE;
	CamelSExpResult *r;
	gint i;

	if (argc > 1 && argv[0]->type == CAMEL_SEXP_RES_STRING) {
		gchar *name = argv[0]->value.string;

		/* shortcut: a match for "" against any header always matches */
		for (i = 1; i < argc && !matched; i++)
			matched = argv[i]->type == CAMEL_SEXP_RES_STRING && argv[i]->value.string[0] == 0;

		if (g_ascii_strcasecmp (name, "x-camel-mlist") == 0) {
			const gchar *list = camel_message_info_get_mlist (fms->info);

			if (list && *list) {
				for (i = 1; i < argc && !matched; i++) {
					if (argv[i]->type == CAMEL_SEXP_RES_STRING) {
						matched = camel_search_header_match (list, argv[i]->value.string, how, CAMEL_SEARCH_TYPE_MLIST, NULL);
						camel_filter_search_log (fms, "Mailing list header value '%s' does %smatch '%s'", list, matched ? "" : "not ", argv[i]->value.string);
					}
				}
			}
		} else if (fms->message || !check_header_in_message_info (fms, argc, argv, how, &matched)) {
			const CamelNameValueArray *headers;
			const gchar *charset = NULL;
			camel_search_t type = CAMEL_SEARCH_TYPE_ENCODED;
			guint ii;
			const gchar *header_name = NULL, *header_value = NULL;

			headers = camel_filter_search_get_headers (fms, f);

			if (camel_search_header_is_address (name)) {
				type = CAMEL_SEARCH_TYPE_ADDRESS_ENCODED;
			} else {
				charset = camel_search_get_default_charset_from_headers (headers);
			}

			for (ii = 0; !matched && camel_name_value_array_get (headers, ii, &header_name, &header_value); ii++) {
				/* empty name means any header */
				if (!name || !*name || !g_ascii_strcasecmp (header_name, name)) {
					for (i = 1; i < argc && !matched; i++) {
						if (argv[i]->type == CAMEL_SEXP_RES_STRING) {
							matched = camel_search_header_match (header_value, argv[i]->value.string, how, type, charset);
							camel_filter_search_log (fms, "Header '%s' value '%s' does %smatch '%s'",
								header_name, header_value, matched ? "" : "not ", argv[i]->value.string);
						}
					}
				}
			}
		}
	}

	r = camel_sexp_result_new (f, CAMEL_SEXP_RES_BOOL);
	r->value.boolean = matched;

	return r;
}

static CamelSExpResult *
header_contains (struct _CamelSExp *f,
                 gint argc,
                 struct _CamelSExpResult **argv,
                 FilterMessageSearch *fms)
{
	return check_header (f, argc, argv, fms, CAMEL_SEARCH_MATCH_CONTAINS);
}

static CamelSExpResult *
header_has_words (struct _CamelSExp *f,
                  gint argc,
                  struct _CamelSExpResult **argv,
                  FilterMessageSearch *fms)
{
	return check_header (f, argc, argv, fms, CAMEL_SEARCH_MATCH_WORD);
}

static CamelSExpResult *
header_matches (struct _CamelSExp *f,
                gint argc,
                struct _CamelSExpResult **argv,
                FilterMessageSearch *fms)
{
	return check_header (f, argc, argv, fms, CAMEL_SEARCH_MATCH_EXACT);
}

static CamelSExpResult *
header_starts_with (struct _CamelSExp *f,
                    gint argc,
                    struct _CamelSExpResult **argv,
                    FilterMessageSearch *fms)
{
	return check_header (f, argc, argv, fms, CAMEL_SEARCH_MATCH_STARTS);
}

static CamelSExpResult *
header_ends_with (struct _CamelSExp *f,
                  gint argc,
                  struct _CamelSExpResult **argv,
                  FilterMessageSearch *fms)
{
	return check_header (f, argc, argv, fms, CAMEL_SEARCH_MATCH_ENDS);
}

static CamelSExpResult *
header_soundex (struct _CamelSExp *f,
                gint argc,
                struct _CamelSExpResult **argv,
                FilterMessageSearch *fms)
{
	return check_header (f, argc, argv, fms, CAMEL_SEARCH_MATCH_SOUNDEX);
}

static CamelSExpResult *
header_exists (struct _CamelSExp *f,
               gint argc,
               struct _CamelSExpResult **argv,
               FilterMessageSearch *fms)
{
	gboolean matched = FALSE;
	CamelSExpResult *r;
	gint i;

	for (i = 0; i < argc && !matched; i++) {
		if (argv[i]->type == CAMEL_SEXP_RES_STRING) {
			const gchar *name = argv[i]->value.string;

			matched = camel_filter_search_get_header (fms, f, name) != NULL;

			camel_filter_search_log (fms, "Header '%s' does %sexist", name, matched ? "" : "not ");
		}
	}

	r = camel_sexp_result_new (f, CAMEL_SEXP_RES_BOOL);
	r->value.boolean = matched;

	return r;
}

static CamelSExpResult *
header_regex (struct _CamelSExp *f,
              gint argc,
              struct _CamelSExpResult **argv,
              FilterMessageSearch *fms)
{
	CamelSExpResult *r = camel_sexp_result_new (f, CAMEL_SEXP_RES_BOOL);
	regex_t pattern;
	gchar *contents = NULL;

	if (argc > 1 && argv[0]->type == CAMEL_SEXP_RES_STRING
	    && (contents = camel_search_get_header_decoded (argv[0]->value.string,
			camel_filter_search_get_header (fms, f, argv[0]->value.string),
			camel_search_get_default_charset_from_headers (camel_filter_search_get_headers (fms, f))))
	    && camel_search_build_match_regex (&pattern, CAMEL_SEARCH_MATCH_REGEX | CAMEL_SEARCH_MATCH_ICASE, argc - 1, argv + 1, fms->error) == 0) {
		r->value.boolean = regexec (&pattern, contents, 0, NULL, 0) == 0;
		camel_filter_search_log (fms, "Regex on header '%s' does %smatch value '%s'",
			argv[0]->value.string, r->value.boolean ? "" : "not ", contents);
		regfree (&pattern);
	} else {
		camel_filter_search_log (fms, "Regex on header not tested, skipping");
		r->value.boolean = FALSE;
	}

	g_free (contents);

	return r;
}

static CamelSExpResult *
header_full_regex (struct _CamelSExp *f,
                   gint argc,
                   struct _CamelSExpResult **argv,
                   FilterMessageSearch *fms)
{
	CamelSExpResult *r = camel_sexp_result_new (f, CAMEL_SEXP_RES_BOOL);
	regex_t pattern;

	if (camel_search_build_match_regex (&pattern, CAMEL_SEARCH_MATCH_REGEX | CAMEL_SEARCH_MATCH_ICASE | CAMEL_SEARCH_MATCH_NEWLINE,
					   argc, argv, fms->error) == 0) {
		const CamelNameValueArray *headers = camel_filter_search_get_headers (fms, f);
		gchar *contents;

		contents = camel_search_get_headers_decoded (headers, NULL);

		r->value.boolean = regexec (&pattern, contents, 0, NULL, 0) == 0;

		g_free (contents);
		regfree (&pattern);
	} else
		r->value.boolean = FALSE;

	camel_filter_search_log (fms, "Full regex on headers does %smatch", r->value.boolean ? "" : "not ");

	return r;
}

static CamelSExpResult *
match_all (struct _CamelSExp *f,
           gint argc,
           struct _CamelSExpTerm **argv,
           FilterMessageSearch *fms)
{
	/* match-all: when dealing with single messages is a no-op */
	CamelSExpResult *r;

	if (argc > 0)
		return camel_sexp_term_eval (f, argv[0]);

	r = camel_sexp_result_new (f, CAMEL_SEXP_RES_BOOL);
	r->value.boolean = TRUE;

	return r;
}

static CamelSExpResult *
body_contains (struct _CamelSExp *f,
               gint argc,
               struct _CamelSExpResult **argv,
               FilterMessageSearch *fms)
{
	CamelSExpResult *r = camel_sexp_result_new (f, CAMEL_SEXP_RES_BOOL);
	CamelMimeMessage *message;
	regex_t pattern;

	if (camel_search_build_match_regex (&pattern, CAMEL_SEARCH_MATCH_ICASE, argc, argv, fms->error) == 0) {
		message = camel_filter_search_get_message (fms, f);
		r->value.boolean = camel_search_message_body_contains ((CamelDataWrapper *) message, &pattern);
		regfree (&pattern);
	} else
		r->value.boolean = FALSE;

	camel_filter_search_log (fms, "Body contains does %smatch", r->value.boolean ? "" : "not ");

	return r;
}

static CamelSExpResult *
body_regex (struct _CamelSExp *f,
            gint argc,
            struct _CamelSExpResult **argv,
            FilterMessageSearch *fms)
{
	CamelSExpResult *r = camel_sexp_result_new (f, CAMEL_SEXP_RES_BOOL);
	CamelMimeMessage *message;
	regex_t pattern;

	if (camel_search_build_match_regex (&pattern, CAMEL_SEARCH_MATCH_ICASE | CAMEL_SEARCH_MATCH_REGEX | CAMEL_SEARCH_MATCH_NEWLINE,
					   argc, argv, fms->error) == 0) {
		message = camel_filter_search_get_message (fms, f);
		r->value.boolean = camel_search_message_body_contains ((CamelDataWrapper *) message, &pattern);
		regfree (&pattern);
	} else
		r->value.boolean = FALSE;

	camel_filter_search_log (fms, "Body regex does %smatch", r->value.boolean ? "" : "not ");

	return r;
}

static CamelSExpResult *
user_flag (struct _CamelSExp *f,
           gint argc,
           struct _CamelSExpResult **argv,
           FilterMessageSearch *fms)
{
	CamelSExpResult *r;
	gboolean truth = FALSE, have_any = FALSE;
	gint i;

	/* performs an OR of all words */
	for (i = 0; i < argc && !truth; i++) {
		if (argv[i]->type == CAMEL_SEXP_RES_STRING
		    && camel_message_info_get_user_flag (fms->info, argv[i]->value.string)) {
			camel_filter_search_log (fms, "User flag '%s' found", argv[i]->value.string);
			have_any = TRUE;
			truth = TRUE;
			break;
		} else if (argv[i]->type == CAMEL_SEXP_RES_STRING) {
			have_any = TRUE;
			camel_filter_search_log (fms, "User flag '%s' not found", argv[i]->value.string);
		}
	}

	if (!have_any)
		camel_filter_search_log (fms, "None user flag tried (possibly invalid filter rule definition)");

	r = camel_sexp_result_new (f, CAMEL_SEXP_RES_BOOL);
	r->value.boolean = truth;

	return r;
}

static CamelSExpResult *
system_flag (struct _CamelSExp *f,
             gint argc,
             struct _CamelSExpResult **argv,
             FilterMessageSearch *fms)
{
	CamelSExpResult *r;

	if (argc != 1 || argv[0]->type != CAMEL_SEXP_RES_STRING)
		camel_sexp_fatal_error (f, _("Invalid arguments to (system-flag)"));

	r = camel_sexp_result_new (f, CAMEL_SEXP_RES_BOOL);
	r->value.boolean = camel_system_flag_get (camel_message_info_get_flags (fms->info), argv[0]->value.string);
	camel_filter_search_log (fms, "System flag '%s' does %smatch", argv[0]->value.string, r->value.boolean ? "" : "not ");

	return r;
}

static CamelSExpResult *
user_tag (struct _CamelSExp *f,
          gint argc,
          struct _CamelSExpResult **argv,
          FilterMessageSearch *fms)
{
	CamelSExpResult *r;
	const gchar *tag;

	if (argc != 1 || argv[0]->type != CAMEL_SEXP_RES_STRING)
		camel_sexp_fatal_error (f, _("Invalid arguments to (user-tag)"));

	tag = camel_message_info_get_user_tag (fms->info, argv[0]->value.string);

	r = camel_sexp_result_new (f, CAMEL_SEXP_RES_STRING);
	r->value.string = g_strdup (tag ? tag : "");

	camel_filter_search_log (fms, "Got user tag '%s' with value '%s'", argv[0]->value.string, r->value.string);

	return r;
}

static CamelSExpResult *
get_sent_date (struct _CamelSExp *f,
               gint argc,
               struct _CamelSExpResult **argv,
               FilterMessageSearch *fms)
{
	gint64 sent_date;
	CamelSExpResult *r;

	if (fms->info) {
		sent_date = camel_message_info_get_date_sent (fms->info);
	} else {
		CamelMimeMessage *message;

		message = camel_filter_search_get_message (fms, f);
		sent_date = camel_mime_message_get_date (message, NULL);
	}

	r = camel_sexp_result_new (f, CAMEL_SEXP_RES_INT);
	r->value.number = sent_date;

	camel_filter_search_log (fms, "Got sent date '%" G_GINT64_FORMAT "'", (gint64) r->value.number);

	return r;
}

static CamelSExpResult *
get_received_date (struct _CamelSExp *f,
                   gint argc,
                   struct _CamelSExpResult **argv,
                   FilterMessageSearch *fms)
{
	gint64 received_date;
	CamelSExpResult *r;

	if (fms->info) {
		received_date = camel_message_info_get_date_received (fms->info);
	} else {
		CamelMimeMessage *message;

		message = camel_filter_search_get_message (fms, f);
		received_date = camel_mime_message_get_date_received (message, NULL);
	}

	r = camel_sexp_result_new (f, CAMEL_SEXP_RES_INT);
	r->value.number = received_date;

	camel_filter_search_log (fms, "Got received date '%" G_GINT64_FORMAT "'", (gint64) r->value.number);

	return r;
}

static CamelSExpResult *
get_current_date (struct _CamelSExp *f,
                  gint argc,
                  struct _CamelSExpResult **argv,
                  FilterMessageSearch *fms)
{
	CamelSExpResult *r;

	r = camel_sexp_result_new (f, CAMEL_SEXP_RES_INT);
	r->value.number = time (NULL);

	camel_filter_search_log (fms, "Got current date '%" G_GINT64_FORMAT "'", (gint64) r->value.number);

	return r;
}

static CamelSExpResult *
get_relative_months (struct _CamelSExp *f,
                     gint argc,
                     struct _CamelSExpResult **argv,
                     FilterMessageSearch *fms)
{
	CamelSExpResult *r;

	if (argc != 1 || argv[0]->type != CAMEL_SEXP_RES_INT) {
		r = camel_sexp_result_new (f, CAMEL_SEXP_RES_BOOL);
		r->value.boolean = FALSE;

		g_debug ("%s: Expecting 1 argument, an integer, but got %d arguments", G_STRFUNC, argc);
		camel_filter_search_log (fms, "Failed relative months: Expecting 1 argument, an integer, but got %d arguments", argc);
	} else {
		r = camel_sexp_result_new (f, CAMEL_SEXP_RES_INT);
		r->value.number = camel_folder_search_util_add_months (time (NULL), argv[0]->value.number);

		camel_filter_search_log (fms, "Got relative months '%" G_GINT64_FORMAT "' for value '%d'", (gint64) r->value.number, argv[0]->value.number);
	}

	return r;
}

static CamelService *
ref_service_for_source (CamelSession *session,
                        const gchar *src)
{
	CamelService *service = NULL;

	/* Source strings are now CamelService UIDs. */
	if (src != NULL)
		service = camel_session_ref_service (session, src);

	/* For backward-compability, also handle CamelService URLs. */
	if (service == NULL && src != NULL) {
		CamelURL *url;

		url = camel_url_new (src, NULL);

		if (service == NULL && url != NULL)
			service = camel_session_ref_service_by_url (
				session, url, CAMEL_PROVIDER_STORE);

		if (service == NULL && url != NULL)
			service = camel_session_ref_service_by_url (
				session, url, CAMEL_PROVIDER_TRANSPORT);

		if (url != NULL)
			camel_url_free (url);
	}

	return service;
}

static CamelSExpResult *
header_source (struct _CamelSExp *f,
               gint argc,
               struct _CamelSExpResult **argv,
               FilterMessageSearch *fms)
{
	CamelMimeMessage *message;
	CamelSExpResult *r;
	const gchar *src;
	CamelService *msg_source = NULL;
	gboolean truth = FALSE;

	if (fms->source) {
		src = fms->source;
	} else {
		message = camel_filter_search_get_message (fms, f);
		src = camel_mime_message_get_source (message);
	}

	if (src)
		msg_source = ref_service_for_source (fms->session, src);

	if (msg_source != NULL) {
		gint ii;

		for (ii = 0; ii < argc && !truth; ii++) {
			if (argv[ii]->type == CAMEL_SEXP_RES_STRING) {
				CamelService *candidate;

				candidate = ref_service_for_source (
					fms->session,
					argv[ii]->value.string);
				if (candidate != NULL) {
					truth = (msg_source == candidate);
					g_object_unref (candidate);

					camel_filter_search_log (fms, "Message source '%s' does %smatch requested source '%s'",
						src, truth ? "" : "not ", argv[ii]->value.string ? argv[ii]->value.string : "NULL");
				} else {
					camel_filter_search_log (fms, "Unknown requested message source '%s' in rule",
						argv[ii]->value.string ? argv[ii]->value.string : "NULL");
				}
			}
		}

		g_object_unref (msg_source);
	} else {
		camel_filter_search_log (fms, "No message source service found for '%s'", src ? src : "NULL");
	}

	r = camel_sexp_result_new (f, CAMEL_SEXP_RES_BOOL);
	r->value.boolean = truth;

	return r;
}

/* remember, the size comparisons are done at Kbytes */
static CamelSExpResult *
get_size (struct _CamelSExp *f,
          gint argc,
          struct _CamelSExpResult **argv,
          FilterMessageSearch *fms)
{
	CamelSExpResult *r;

	r = camel_sexp_result_new (f, CAMEL_SEXP_RES_INT);
	r->value.number = camel_message_info_get_size (fms->info) / 1024;

	camel_filter_search_log (fms, "Got message size '%" G_GINT64_FORMAT "' (from %" G_GINT64_FORMAT ")",
		(gint64) r->value.number, (gint64) camel_message_info_get_size (fms->info));

	return r;
}

#ifndef G_OS_WIN32
static void
child_setup_func (gpointer user_data)
{
	setsid ();
}
#else
#define child_setup_func NULL
#endif

typedef struct {
	gint child_status;
	GMainLoop *loop;
} child_watch_data_t;

static void
child_watch (GPid pid,
             gint status,
             gpointer data)
{
	child_watch_data_t *child_watch_data = data;

	g_spawn_close_pid (pid);

	child_watch_data->child_status = status;
	g_main_loop_quit (child_watch_data->loop);
}

static gint
run_command (struct _CamelSExp *f,
             gint argc,
             struct _CamelSExpResult **argv,
             FilterMessageSearch *fms)
{
	CamelMimeMessage *message;
	CamelStream *stream;
	gint i;
	gint pipe_to_child;
	GPid child_pid;
	GError *error = NULL;
	GPtrArray *args;
	child_watch_data_t child_watch_data;
	GSource *source;
	GMainContext *context;

	if (argc < 1 || argv[0]->value.string[0] == '\0')
		return 0;

	args = g_ptr_array_new ();
	for (i = 0; i < argc; i++)
		g_ptr_array_add (args, argv[i]->value.string);
	g_ptr_array_add (args, NULL);

	if (!g_spawn_async_with_pipes (NULL,
				       (gchar **) args->pdata,
				       NULL,
				       G_SPAWN_DO_NOT_REAP_CHILD |
				       G_SPAWN_SEARCH_PATH |
				       G_SPAWN_STDOUT_TO_DEV_NULL |
				       G_SPAWN_STDERR_TO_DEV_NULL,
				       child_setup_func,
				       NULL,
				       &child_pid,
				       &pipe_to_child,
				       NULL,
				       NULL,
				       &error)) {
		g_ptr_array_free (args, TRUE);

		g_set_error (
			fms->error, CAMEL_ERROR, CAMEL_ERROR_GENERIC,
			_("Failed to create child process “%s”: %s"),
			argv[0]->value.string, error->message);
		g_error_free (error);
		return -1;
	}

	g_ptr_array_free (args, TRUE);

	message = camel_filter_search_get_message (fms, f);

	stream = camel_stream_fs_new_with_fd (pipe_to_child);
	camel_data_wrapper_write_to_stream_sync (
		CAMEL_DATA_WRAPPER (message), stream, fms->cancellable, NULL);
	camel_stream_flush (stream, fms->cancellable, NULL);
	g_object_unref (stream);

	context = g_main_context_new ();
	child_watch_data.loop = g_main_loop_new (context, FALSE);
	g_main_context_unref (context);

	source = g_child_watch_source_new (child_pid);
	g_source_set_callback (source, (GSourceFunc) child_watch, &child_watch_data, NULL);
	g_source_attach (source, g_main_loop_get_context (child_watch_data.loop));
	g_source_unref (source);

	g_main_loop_run (child_watch_data.loop);
	g_main_loop_unref (child_watch_data.loop);

#ifndef G_OS_WIN32
	if (WIFEXITED (child_watch_data.child_status))
		return WEXITSTATUS (child_watch_data.child_status);
	else
		return -1;
#else
	return child_watch_data.child_status;
#endif
}

static CamelSExpResult *
pipe_message (struct _CamelSExp *f,
              gint argc,
              struct _CamelSExpResult **argv,
              FilterMessageSearch *fms)
{
	CamelSExpResult *r;
	gint retval, i;

	/* make sure all args are strings */
	for (i = 0; i < argc; i++) {
		if (argv[i]->type != CAMEL_SEXP_RES_STRING) {
			retval = -1;
			goto done;
		}
	}

	retval = run_command (f, argc, argv, fms);

 done:
	r = camel_sexp_result_new (f, CAMEL_SEXP_RES_INT);
	r->value.number = retval;

	camel_filter_search_log (fms, "Pipe message result: %" G_GINT64_FORMAT, (gint64) r->value.number);

	return r;
}

static CamelSExpResult *
junk_test (struct _CamelSExp *f,
           gint argc,
           struct _CamelSExpResult **argv,
           FilterMessageSearch *fms)
{
	CamelSExpResult *r;
	CamelMessageInfo *info = fms->info;
	CamelJunkFilter *junk_filter;
	CamelMessageFlags flags;
	CamelMimeMessage *message;
	CamelJunkStatus status;
	const GHashTable *ht;
	const CamelNameValueArray *info_headers;
	gboolean sender_is_known;
	gboolean message_is_junk = FALSE;
	GError *error = NULL;

	/* Check if the message is already classified. */

	flags = camel_message_info_get_flags (info);

	if (flags & CAMEL_MESSAGE_JUNK) {
		message_is_junk = TRUE;
		if (camel_debug ("junk"))
			printf ("Message '%s' has a Junk flag set already, skipping junk test...\n", camel_message_info_get_uid (info));
		camel_filter_search_log (fms, "Message '%s' has a Junk flag set already, skipping junk test", camel_message_info_get_uid (info));
		goto done;
	}

	if (flags & CAMEL_MESSAGE_NOTJUNK) {
		if (camel_debug ("junk"))
			printf ("Message '%s' has a NotJunk flag set already, skipping junk test...\n", camel_message_info_get_uid (info));
		camel_filter_search_log (fms, "Message '%s' has a NotJunk flag set already, skipping junk test", camel_message_info_get_uid (info));
		goto done;
	}

	/* If the sender is known, the message is not junk.
	   Do this before header test, to be able to override server-side set headers. */

	sender_is_known = camel_session_lookup_addressbook (
		fms->session, camel_message_info_get_from (info));
	camel_filter_search_log (fms, "Sender '%s' of message '%s' is %sin any address book",
		camel_message_info_get_from (info),
		camel_message_info_get_uid (info),
		sender_is_known ? "" : "not ");
	if (camel_debug ("junk"))
		printf ("Sender '%s' of message '%s' in book? %d\n",
			camel_message_info_get_from (info),
			camel_message_info_get_uid (info),
			sender_is_known);
	if (sender_is_known)
		goto done;

	/* Check the headers for a junk designation. */

	ht = camel_session_get_junk_headers (fms->session);

	camel_message_info_property_lock (info);

	info_headers = camel_message_info_get_headers (info);
	if (info_headers) {
		guint len, ii;

		len = camel_name_value_array_get_length (info_headers);
		for (ii = 0; ii < len; ii++) {
			const gchar *hdr_name = NULL;
			const gchar *hdr_value = NULL;
			const gchar *junk_value = NULL;

			if (!camel_name_value_array_get (info_headers, ii, &hdr_name, &hdr_value))
				continue;

			if (!hdr_name || !hdr_value)
				continue;

			junk_value = g_hash_table_lookup ((GHashTable *) ht, hdr_name);

			message_is_junk =
				(junk_value != NULL) &&
				(camel_strstrcase (hdr_value, junk_value) != NULL);

			if (message_is_junk) {
				if (camel_debug ("junk"))
					printf ("Message '%s' contains \"%s: %s\"",
						camel_message_info_get_uid (info),
						hdr_name, junk_value);
				camel_filter_search_log (fms, "Message '%s' is junk, because contains header '%s' with value '%s'",
					camel_message_info_get_uid (info), hdr_name, junk_value);
				camel_message_info_property_unlock (info);
				goto done;
			}
		}
	}

	camel_message_info_property_unlock (info);

	/* Not every message info has headers available, thus try headers of the message itself */
	message = camel_filter_search_get_message (fms, f);
	if (message) {
		const CamelNameValueArray *headers;
		const gchar *raw_name = NULL, *raw_value = NULL;
		guint ii;

		headers = camel_medium_get_headers (CAMEL_MEDIUM (message));
		for (ii = 0; camel_name_value_array_get (headers, ii, &raw_name, &raw_value); ii++) {
			const gchar *value;
			if (!raw_name)
				continue;

			value = g_hash_table_lookup ((GHashTable *) ht, raw_name);
			if (!value)
				continue;

			message_is_junk = camel_strstrcase (raw_value, value) != NULL;

			if (message_is_junk) {
				if (camel_debug ("junk")) {
					printf ("Message '%s' contains \"%s: %s\"",
						camel_message_info_get_uid (info),
						raw_name, value);
				}
				camel_filter_search_log (fms, "Message '%s' is junk, because contains header '%s' with value '%s'",
					camel_message_info_get_uid (info), raw_name, value);
				goto done;
			}
		}
	} else {
		goto done;
	}

	/* Consult 3rd party junk filtering software. */

	junk_filter = camel_session_get_junk_filter (fms->session);
	if (junk_filter == NULL) {
		camel_filter_search_log (fms, "No junk filter set");
		goto done;
	}

	status = camel_junk_filter_classify (
		junk_filter, message, fms->cancellable, &error);

	if (error == NULL) {
		const gchar *status_desc;

		switch (status) {
			case CAMEL_JUNK_STATUS_INCONCLUSIVE:
				status_desc = "inconclusive";
				message_is_junk = FALSE;
				break;
			case CAMEL_JUNK_STATUS_MESSAGE_IS_JUNK:
				status_desc = "junk";
				message_is_junk = TRUE;
				break;
			case CAMEL_JUNK_STATUS_MESSAGE_IS_NOT_JUNK:
				status_desc = "not junk";
				message_is_junk = FALSE;
				break;
			default:
				g_warn_if_reached ();
				status_desc = "invalid";
				message_is_junk = FALSE;
				break;
		}

		camel_filter_search_log (fms, "Junk filter classified message '%s' as '%s'", camel_message_info_get_uid (info), status_desc);
		if (camel_debug ("junk"))
			printf (
				"Junk filter classification for message '%s': %s\n",
				camel_message_info_get_uid (info),
				status_desc);
	} else {
		g_warn_if_fail (status == CAMEL_JUNK_STATUS_ERROR);
		camel_filter_search_log (fms, "Junk classify failed for message '%s' with error '%s'", camel_message_info_get_uid (info), error->message);
		if (camel_debug ("junk"))
			printf ("Junk classify failed for message '%s' with error: %s\n", camel_message_info_get_uid (info), error->message);
		if (!g_error_matches (error, G_IO_ERROR, G_IO_ERROR_CANCELLED))
			g_warning ("%s: %s", G_STRFUNC, error->message);
		g_error_free (error);
		message_is_junk = FALSE;
	}

 done:
	camel_filter_search_log (fms, "Finish message '%s' junk classify as %sJunk", camel_message_info_get_uid (info), message_is_junk ? "" : "not ");
	if (camel_debug ("junk"))
		printf (
			"Message '%s' is determined to be %s\n",
			camel_message_info_get_uid (info),
			message_is_junk ? "*JUNK*" : "clean");

	r = camel_sexp_result_new (f, CAMEL_SEXP_RES_BOOL);
	r->value.number = message_is_junk;

	return r;
}

/* this is copied from Evolution's libemail-engine/e-mail-folder-utils.c */
static gchar *
mail_folder_uri_build (CamelStore *store,
                       const gchar *folder_name)
{
	const gchar *uid;
	gchar *encoded_name;
	gchar *encoded_uid;
	gchar *uri;

	g_return_val_if_fail (CAMEL_IS_STORE (store), NULL);
	g_return_val_if_fail (folder_name != NULL, NULL);

	/* Skip the leading slash, if present. */
	if (*folder_name == '/')
		folder_name++;

	uid = camel_service_get_uid (CAMEL_SERVICE (store));

	encoded_uid = camel_url_encode (uid, ":;@/");
	encoded_name = camel_url_encode (folder_name, "#");

	uri = g_strdup_printf ("folder://%s/%s", encoded_uid, encoded_name);

	g_free (encoded_uid);
	g_free (encoded_name);

	return uri;
}

static CamelSExpResult *
message_location (struct _CamelSExp *f,
		  gint argc,
		  struct _CamelSExpResult **argv,
		  FilterMessageSearch *fms)
{
	CamelSExpResult *r;
	gboolean same = FALSE;

	if (argc != 1 || argv[0]->type != CAMEL_SEXP_RES_STRING)
		camel_sexp_fatal_error (f, _("Invalid arguments to (message-location)"));

	if (fms->folder && argv[0]->value.string) {
		CamelStore *store;
		const gchar *name;
		gchar *uri;

		store = camel_folder_get_parent_store (fms->folder);
		name = camel_folder_get_full_name (fms->folder);
		uri = mail_folder_uri_build (store, name);

		same = g_str_equal (uri, argv[0]->value.string);
		camel_filter_search_log (fms, "Message location '%s' is %ssame as requested '%s'",
			uri, same ? "" : "not ", argv[0]->value.string);

		g_free (uri);
	} else {
		camel_filter_search_log (fms, "Message location cannot check, have %sfolder or %srequest",
			fms->folder ? "" : "no ", argv[0]->value.string ? "" : "no ");
	}

	r = camel_sexp_result_new (f, CAMEL_SEXP_RES_BOOL);
	r->value.boolean = same;

	return r;
}

static CamelSExpResult *
make_time_func (CamelSExp *sexp,
		gint argc,
		CamelSExpResult **argv,
		FilterMessageSearch *fms)
{
	CamelSExpResult *res;

	camel_filter_search_log (fms, "Calling 'make-time'");

	res = camel_sexp_result_new (sexp, CAMEL_SEXP_RES_TIME);
	res->value.time = camel_folder_search_util_make_time (argc, argv);

	return res;
}

static CamelSExpResult *
compare_date_func (CamelSExp *sexp,
		   gint argc,
		   CamelSExpResult **argv,
		   FilterMessageSearch *fms)
{
	CamelSExpResult *res;

	res = camel_sexp_result_new (sexp, CAMEL_SEXP_RES_INT);
	res->value.number = 0;

	if (argc == 2) {
		gint64 t1, t2;

		if (argv[0]->type == CAMEL_SEXP_RES_INT)
			t1 = argv[0]->value.number;
		else if (argv[0]->type == CAMEL_SEXP_RES_TIME)
			t1 = (gint64) argv[0]->value.time;
		else {
			camel_filter_search_log (fms, "compare-date result:%d (incorrect first argument type)", res->value.number);
			return res;
		}

		if (argv[1]->type == CAMEL_SEXP_RES_INT)
			t2 = argv[1]->value.number;
		else if (argv[1]->type == CAMEL_SEXP_RES_TIME)
			t2 = (gint64) argv[1]->value.time;
		else {
			camel_filter_search_log (fms, "compare-date result:%d (incorrect second argument type)", res->value.number);
			return res;
		}

		res->value.number = camel_folder_search_util_compare_date (t1, t2);
	}

	camel_filter_search_log (fms, "compare-date result:%d", res->value.number);

	return res;
}

static const gchar *
camel_search_result_to_string (gint value)
{
	return value == CAMEL_SEARCH_ERROR ? "ERROR" :
	       value == CAMEL_SEARCH_NOMATCH ? "NOMATCH" :
	       value == CAMEL_SEARCH_MATCHED ? "MATCHED" : "???";
}

/**
 * camel_filter_search_match_with_log:
 * @session:
 * @get_message: (scope async): function to retrieve the message if necessary
 * @user_data: data for above
 * @info:
 * @source:
 * @folder: in which folder the message is stored
 * @expression:
 * @logfile: (nullable): an optional log file to write logging information to, or %NULL
 * @cancellable: (allow-none): a #GCancellable, or %NULL
 * @error: return location for a #GError, or %NULL
 *
 * Returns: one of CAMEL_SEARCH_MATCHED, CAMEL_SEARCH_NOMATCH, or
 * CAMEL_SEARCH_ERROR.
 *
 * Since 3.24
 **/
gint
camel_filter_search_match_with_log (CamelSession *session,
				    CamelFilterSearchGetMessageFunc get_message,
				    gpointer user_data,
				    CamelMessageInfo *info,
				    const gchar *source,
				    CamelFolder *folder,
				    const gchar *expression,
				    FILE *logfile,
				    GCancellable *cancellable,
				    GError **error)
{
	FilterMessageSearch fms;
	CamelSExp *sexp;
	CamelSExpResult *result;
	gint retval;
	GError *local_error = NULL;
	gint i;

	fms.session = session;
	fms.get_message = get_message;
	fms.get_message_data = user_data;
	fms.message = NULL;
	fms.info = info;
	fms.source = source;
	fms.folder = folder;
	fms.logfile = logfile;
	fms.cancellable = cancellable;
	fms.error = &local_error;

	sexp = camel_sexp_new ();

	for (i = 0; i < G_N_ELEMENTS (symbols); i++) {
		if (symbols[i].type == 1)
			camel_sexp_add_ifunction (sexp, 0, symbols[i].name, (CamelSExpIFunc) symbols[i].func, &fms);
		else
			camel_sexp_add_function (sexp, 0, symbols[i].name, symbols[i].func, &fms);
	}

	camel_sexp_input_text (sexp, expression, strlen (expression));
	if (camel_sexp_parse (sexp) == -1) {
		if (!local_error) {
			/* A filter search is a search through your filters,
			 * ie. your filters is the corpus being searched thru. */
			g_set_error (
				&local_error, CAMEL_ERROR, CAMEL_ERROR_GENERIC,
				_("Error executing filter search: %s: %s"),
				camel_sexp_error (sexp), expression);
		}
		goto error;
	}

	result = camel_sexp_eval (sexp);
	if (result == NULL) {
		if (!local_error)
			g_set_error (
				&local_error, CAMEL_ERROR, CAMEL_ERROR_GENERIC,
				_("Error executing filter search: %s: %s"),
				camel_sexp_error (sexp), expression);
		goto error;
	}

	if (local_error) {
		camel_sexp_result_free (sexp, result);
		goto error;
	}

	if (result->type == CAMEL_SEXP_RES_BOOL)
		retval = result->value.boolean ? CAMEL_SEARCH_MATCHED : CAMEL_SEARCH_NOMATCH;
	else
		retval = CAMEL_SEARCH_NOMATCH;

	camel_sexp_result_free (sexp, result);
	g_object_unref (sexp);

	if (fms.message)
		g_object_unref (fms.message);

	if (logfile) {
		camel_filter_search_log (&fms, "Finished test of message uid:%s subject:'%s' from '%s : %s' as %s",
			camel_message_info_get_uid (info), camel_message_info_get_subject (info),
			folder ? camel_service_get_display_name (CAMEL_SERVICE (camel_folder_get_parent_store (folder))) : "NULL",
			folder ? camel_folder_get_full_name (folder) : "NULL",
			camel_search_result_to_string (retval));
	}

	return retval;

 error:
	if (fms.message)
		g_object_unref (fms.message);

	g_object_unref (sexp);

	if (logfile) {
		camel_filter_search_log (&fms, "Finished test of message uid:%s subject:'%s' from '%s : %s' as ERROR: '%s'",
			camel_message_info_get_uid (info), camel_message_info_get_subject (info),
			folder ? camel_service_get_display_name (CAMEL_SERVICE (camel_folder_get_parent_store (folder))) : "NULL",
			folder ? camel_folder_get_full_name (folder) : "NULL",
			local_error ? local_error->message : "Unknown error");
	}

	if (local_error)
		g_propagate_error (error, local_error);

	return CAMEL_SEARCH_ERROR;
}

/**
 * camel_filter_search_match:
 * @session:
 * @get_message: (scope async): function to retrieve the message if necessary
 * @user_data: data for above
 * @info:
 * @source:
 * @folder: in which folder the message is stored
 * @expression:
 * @cancellable: (allow-none): a #GCancellable, or %NULL
 * @error: return location for a #GError, or %NULL
 *
 * Returns: one of CAMEL_SEARCH_MATCHED, CAMEL_SEARCH_NOMATCH, or
 * CAMEL_SEARCH_ERROR.
 **/
gint
camel_filter_search_match (CamelSession *session,
                           CamelFilterSearchGetMessageFunc get_message,
                           gpointer user_data,
                           CamelMessageInfo *info,
                           const gchar *source,
			   CamelFolder *folder,
                           const gchar *expression,
			   GCancellable *cancellable,
                           GError **error)
{
	return camel_filter_search_match_with_log (session, get_message, user_data, info,
		source, folder, expression, NULL, cancellable, error);
}
