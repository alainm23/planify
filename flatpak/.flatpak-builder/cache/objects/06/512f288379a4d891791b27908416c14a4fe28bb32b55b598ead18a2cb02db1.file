/* -*- Mode: C; tab-width: 8; indent-tabs-mode: t; c-basic-offset: 8 -*- */
/* camel-url.c : utility functions to parse URLs
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
 * Authors: Dan Winship <danw@ximian.com>
 *          Jeffrey Stedfast <fejj@ximian.com>
 */

#include "evolution-data-server-config.h"

#include <ctype.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include <glib/gi18n-lib.h>

#include "camel-mime-utils.h"
#include "camel-object.h"
#include "camel-service.h"
#include "camel-string-utils.h"
#include "camel-url.h"

static void copy_param (GQuark key_id, gpointer data, gpointer user_data);
static void output_param (GQuark key_id, gpointer data, gpointer user_data);

static void append_url_encoded (GString *str, const gchar *in, const gchar *extra_enc_chars);

GType
camel_url_get_type (void)
{
	static GType type = G_TYPE_INVALID;

	if (G_UNLIKELY (type == G_TYPE_INVALID))
		type = g_boxed_type_register_static (
			"CamelURL",
			(GBoxedCopyFunc) camel_url_copy,
			(GBoxedFreeFunc) camel_url_free);

	return type;
}

/**
 * camel_url_new_with_base:
 * @base: a base URL
 * @url_string: the URL
 *
 * Parses @url_string relative to @base.
 *
 * Returns: a parsed #CamelURL
 **/
CamelURL *
camel_url_new_with_base (CamelURL *base,
                         const gchar *url_string)
{
	CamelURL *url;
	const gchar *end, *hash, *colon, *semi, *at, *slash, *question;
	const gchar *p;

#ifdef G_OS_WIN32
	const gchar *start = url_string;
#endif

	g_return_val_if_fail (url_string != NULL, NULL);

	url = g_new0 (CamelURL, 1);

	/* See RFC1808 for details. IF YOU CHANGE ANYTHING IN THIS
	 * FUNCTION, RUN tests/misc/url AFTERWARDS.
	 */

	/* Find fragment.  RFC 1808 2.4.1 */
	end = hash = strchr (url_string, '#');
	if (hash) {
		if (hash[1]) {
			url->fragment = g_strdup (hash + 1);
			camel_url_decode (url->fragment);
		}
	} else
		end = url_string + strlen (url_string);

	/* Find protocol: initial [a-z+.-]* substring until ":" */
	p = url_string;
	while (p < end && (isalnum ((guchar) * p) ||
			   *p == '.' || *p == '+' || *p == '-'))
		p++;

	if (p > url_string && *p == ':') {
		url->protocol = g_strndup (url_string, p - url_string);
		camel_strdown (url->protocol);
		url_string = p + 1;
	}

	if (!*url_string && !base)
		return url;

#ifdef G_OS_WIN32
	if (url->protocol && !strcmp (url->protocol, "file")) {
		url->path = g_filename_from_uri (start, &url->host, NULL);
		return url;
	}
#endif

	/* Check for authority */
	if (strncmp (url_string, "//", 2) == 0) {
		url_string += 2;

		slash = url_string + strcspn (url_string, "/#");
		at = strchr (url_string, '@');
		if (at && at < slash) {
			colon = strchr (url_string, ':');
			if (colon && colon < at) {
				/* XXX We used to extract and store the
				 *     password here, now we just eat it. */
			} else {
				colon = at;
			}

			semi = strchr (url_string, ';');
			if (semi && semi < colon &&
			    !g_ascii_strncasecmp (semi, ";auth=", 6)) {
				url->authmech = g_strndup (
					semi + 6, colon - semi - 6);
				camel_url_decode (url->authmech);
			} else {
				url->authmech = NULL;
				semi = colon;
			}

			url->user = g_strndup (url_string, semi - url_string);
			camel_url_decode (url->user);
			url_string = at + 1;
		} else
			url->user = url->authmech = NULL;

		/* Find host and port. */
		colon = strchr (url_string, ':');
		if (colon && colon < slash) {
			url->host = g_strndup (url_string, colon - url_string);
			url->port = strtoul (colon + 1, NULL, 10);
		} else {
			url->host = g_strndup (url_string, slash - url_string);
			camel_url_decode (url->host);
			url->port = 0;
		}

		url_string = slash;
	}

	/* Find query */
	question = memchr (url_string, '?', end - url_string);
	if (question) {
		if (question[1]) {
			url->query = g_strndup (
				question + 1, end - (question + 1));
			camel_url_decode (url->query);
		}
		end = question;
	}

	/* Find parameters */
	semi = memchr (url_string, ';', end - url_string);
	if (semi) {
		if (semi[1]) {
			const gchar *cur, *p, *eq;
			gchar *name, *value;

			for (cur = semi + 1; cur < end; cur = p + 1) {
				p = memchr (cur, ';', end - cur);
				if (!p)
					p = end;
				eq = memchr (cur, '=', p - cur);
				if (eq) {
					name = g_strndup (cur, eq - cur);
					value = g_strndup (eq + 1, p - (eq + 1));
					camel_url_decode (value);
				} else {
					name = g_strndup (cur, p - cur);
					value = g_strdup ("");
				}
				camel_url_decode (name);
				g_datalist_set_data_full (
					&url->params, name, value, g_free);
				g_free (name);
			}
		}
		end = semi;
	}

	if (end != url_string) {
		url->path = g_strndup (url_string, end - url_string);
		camel_url_decode (url->path);
	}

	/* Apply base URL. Again, this is spelled out in RFC 1808. */
	if (base && !url->protocol && url->host)
		url->protocol = g_strdup (base->protocol);
	else if (base && !url->protocol) {
		if (!url->user && !url->authmech &&
		    !url->host && !url->port && !url->path &&
		    !url->params && !url->query && !url->fragment)
			url->fragment = g_strdup (base->fragment);

		url->protocol = g_strdup (base->protocol);
		url->user = g_strdup (base->user);
		url->authmech = g_strdup (base->authmech);
		url->host = g_strdup (base->host);
		url->port = base->port;

		if (!url->path) {
			url->path = g_strdup (base->path);
			if (!url->params) {
				g_datalist_foreach (&base->params, copy_param,
						    &url->params);
				if (!url->query)
					url->query = g_strdup (base->query);
			}
		} else if (*url->path != '/') {
			gchar *newpath, *last, *p, *q;

			/* the base->path is NULL if given Content-Base url was without last slash,
			 * i.e. like "http://example.com" (this expected only "http://example.com/") */
			last = base->path ? strrchr (base->path, '/') : NULL;
			if (last) {
				newpath = g_strdup_printf (
					"%.*s/%s",
					(gint)(last - base->path),
					base->path,
					url->path);
			} else
				newpath = g_strdup_printf ("/%s", url->path);

			/* Remove "./" where "." is a complete segment. */
			for (p = newpath + 1; *p; ) {
				if (*(p - 1) == '/' &&
				    *p == '.' && *(p + 1) == '/')
					memmove (p, p + 2, strlen (p + 2) + 1);
				else
					p++;
			}
			/* Remove "." at end. */
			if (p > newpath + 2 &&
			    *(p - 1) == '.' && *(p - 2) == '/')
				*(p - 1) = '\0';
			/* Remove "<segment>/../" where <segment> != ".." */
			for (p = newpath + 1; *p; ) {
				if (!strncmp (p, "../", 3)) {
					p += 3;
					continue;
				}
				q = strchr (p + 1, '/');
				if (!q)
					break;
				if (strncmp (q, "/../", 4) != 0) {
					p = q + 1;
					continue;
				}
				memmove (p, q + 4, strlen (q + 4) + 1);
				p = newpath + 1;
			}
			/* Remove "<segment>/.." at end */
			q = strrchr (newpath, '/');
			if (q && !strcmp (q, "/..")) {
				p = q - 1;
				while (p > newpath && *p != '/')
					p--;
				if (strncmp (p, "/../", 4) != 0)
					*(p + 1) = 0;
			}
			g_free (url->path);
			url->path = newpath;
		}
	}

	return url;
}

static void
copy_param (GQuark key_id,
            gpointer data,
            gpointer user_data)
{
	GData **copy = user_data;

	g_datalist_id_set_data_full (copy, key_id, g_strdup (data), g_free);
}

/**
 * camel_url_new:
 * @url_string: a URL string
 * @error: return location for a #GError, or %NULL
 *
 * Parses an absolute URL.
 *
 * Returns: a #CamelURL if it can be parsed, or %NULL otherwise
 **/
CamelURL *
camel_url_new (const gchar *url_string,
               GError **error)
{
	CamelURL *url;

	if (!url_string || !*url_string)
		return NULL;

	url = camel_url_new_with_base (NULL, url_string);

	if (!url->protocol) {
		camel_url_free (url);
		g_set_error (
			error, CAMEL_ERROR, CAMEL_ERROR_GENERIC,
			_("Could not parse URL “%s”"), url_string);
		return NULL;
	}
	return url;
}

/**
 * camel_url_to_string:
 * @url: a #CamelURL
 * @flags: additional translation options
 *
 * Flatten a #CamelURL into a string.
 *
 * Returns: a string representing @url, which the caller must free
 **/
gchar *
camel_url_to_string (CamelURL *url,
                     CamelURLFlags flags)
{
	GString *str;
	gchar *return_result;

	g_return_val_if_fail (url != NULL, NULL);

	/* IF YOU CHANGE ANYTHING IN THIS FUNCTION, RUN
	 * tests/misc/url AFTERWARD.
	 */

#ifdef G_OS_WIN32
	if (url->protocol && !strcmp (url->protocol, "file"))
		return g_filename_to_uri (url->path, url->host, NULL);
#endif /* G_OS_WIN32 */

	str = g_string_sized_new (20);

	if (url->protocol)
		g_string_append_printf (str, "%s:", url->protocol);

	if (url->host) {
		g_string_append (str, "//");
		if (url->user) {
			append_url_encoded (str, url->user, ":;@/");
			if (url->authmech && *url->authmech && !(flags & CAMEL_URL_HIDE_AUTH)) {
				g_string_append (str, ";auth=");
				append_url_encoded (str, url->authmech, ":@/");
			}
			g_string_append_c (str, '@');
		}
		append_url_encoded (str, url->host, ":/");
		if (url->port)
			g_string_append_printf (str, ":%d", url->port);
		if (!url->path && (url->params || url->query || url->fragment))
			g_string_append_c (str, '/');
	}

	if (url->path)
		append_url_encoded (str, url->path, ";?");
	if (url->params && !(flags & CAMEL_URL_HIDE_PARAMS))
		g_datalist_foreach (&url->params, output_param, str);
	if (url->query) {
		g_string_append_c (str, '?');
		append_url_encoded (str, url->query, NULL);
	}
	if (url->fragment) {
		g_string_append_c (str, '#');
		append_url_encoded (str, url->fragment, NULL);
	}

	return_result = str->str;
	g_string_free (str, FALSE);

	return return_result;
}

static void
output_param (GQuark key_id,
              gpointer data,
              gpointer user_data)
{
	GString *str = user_data;

	g_string_append_c (str, ';');
	append_url_encoded (str, g_quark_to_string (key_id), "?=");
	if (*(gchar *) data) {
		g_string_append_c (str, '=');
		append_url_encoded (str, data, "?");
	}
}

/**
 * camel_url_free:
 * @url: a #CamelURL
 *
 * Frees @url.
 **/
void
camel_url_free (CamelURL *url)
{
	if (url) {
		if (url->user)
			memset (url->user, 0, strlen (url->user));
		if (url->host)
			memset (url->host, 0, strlen (url->host));
		g_free (url->protocol);
		g_free (url->user);
		g_free (url->authmech);
		g_free (url->host);
		g_free (url->path);
		g_datalist_clear (&url->params);
		g_free (url->query);
		g_free (url->fragment);

		g_free (url);
	}
}

/**
 * camel_url_set_protocol:
 * @url: a #CamelURL
 * @protocol: protocol schema
 *
 * Set the protocol of a #CamelURL.
 **/
void
camel_url_set_protocol (CamelURL *url,
                        const gchar *protocol)
{
	g_return_if_fail (url != NULL);

	g_free (url->protocol);
	url->protocol = g_strdup (protocol);
}

/**
 * camel_url_set_user:
 * @url: a #CamelURL
 * @user: username
 *
 * Set the user of a #CamelURL.
 **/
void
camel_url_set_user (CamelURL *url,
                    const gchar *user)
{
	g_return_if_fail (url != NULL);

	g_free (url->user);
	url->user = g_strdup (user);
}

/**
 * camel_url_set_authmech:
 * @url: a #CamelURL
 * @authmech: authentication mechanism
 *
 * Set the authmech of a #CamelURL.
 **/
void
camel_url_set_authmech (CamelURL *url,
                        const gchar *authmech)
{
	g_return_if_fail (url != NULL);

	g_free (url->authmech);
	url->authmech = g_strdup (authmech);
}

/**
 * camel_url_set_host:
 * @url: a #CamelURL
 * @host: hostname
 *
 * Set the hostname of a #CamelURL.
 **/
void
camel_url_set_host (CamelURL *url,
                    const gchar *host)
{
	g_return_if_fail (url != NULL);

	g_free (url->host);
	url->host = g_strdup (host);
}

/**
 * camel_url_set_path:
 * @url: a #CamelURL
 * @path: path
 *
 * Set the path component of a #CamelURL.
 **/
void
camel_url_set_path (CamelURL *url,
                    const gchar *path)
{
	g_return_if_fail (url != NULL);

	g_free (url->path);
	url->path = g_strdup (path);
}

/**
 * camel_url_set_query:
 * @url: a #CamelURL
 * @query: url query
 *
 * Set the query of a #CamelURL.
 **/
void
camel_url_set_query (CamelURL *url,
                     const gchar *query)
{
	g_return_if_fail (url != NULL);

	g_free (url->query);
	url->query = g_strdup (query);
}

/**
 * camel_url_set_fragment:
 * @url: a #CamelURL
 * @fragment: url fragment
 *
 * Set the fragment of a #CamelURL.
 **/
void
camel_url_set_fragment (CamelURL *url,
                        const gchar *fragment)
{
	g_return_if_fail (url != NULL);

	g_free (url->fragment);
	url->fragment = g_strdup (fragment);
}

/**
 * camel_url_set_port:
 * @url: a #CamelURL
 * @port: port
 *
 * Set the port on a #CamelURL.
 **/
void
camel_url_set_port (CamelURL *url,
                    gint port)
{
	g_return_if_fail (url != NULL);

	url->port = port;
}

/**
 * camel_url_set_param:
 * @url: a #CamelURL
 * @name: name of the param to set
 * @value: value of the param to set
 *
 * Set a param on the #CamelURL.
 **/
void
camel_url_set_param (CamelURL *url,
                     const gchar *name,
                     const gchar *value)
{
	g_return_if_fail (url != NULL);

	if (value)
		g_datalist_set_data_full (&url->params, name, g_strdup (value), g_free);
	else
		g_datalist_remove_data (&url->params, name);
}

/**
 * camel_url_get_param:
 * @url: a #CamelURL
 * @name: name of the param
 *
 * Get the value of the specified param on the URL.
 *
 * Returns: the value of a param if found or %NULL otherwise
 **/
const gchar *
camel_url_get_param (CamelURL *url,
                     const gchar *name)
{
	g_return_val_if_fail (url != NULL, NULL);

	return g_datalist_get_data (&url->params, name);
}

/* From RFC 2396 2.4.3, the characters that should always be encoded */
static const gchar url_encoded_char[] = {
	1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,  /* 0x00 - 0x0f */
	1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,  /* 0x10 - 0x1f */
	1, 0, 1, 1, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,  /*  ' ' - '/'  */
	0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 1, 0,  /*  '0' - '?'  */
	0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,  /*  '@' - 'O'  */
	0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 0,  /*  'P' - '_'  */
	1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,  /*  '`' - 'o'  */
	0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 0, 1,  /*  'p' - 0x7f */
	1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
	1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
	1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
	1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
	1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
	1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
	1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
	1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1
};

static void
append_url_encoded (GString *str,
                    const gchar *in,
                    const gchar *extra_enc_chars)
{
	const guchar *s = (const guchar *) in;

	while (*s) {
		if (url_encoded_char[*s] ||
		    (extra_enc_chars && strchr (extra_enc_chars, *s)))
			g_string_append_printf (str, "%%%02x", (gint) * s++);
		else
			g_string_append_c (str, *s++);
	}
}

/**
 * camel_url_encode:
 * @part: a URL part
 * @escape_extra: additional characters beyond " \"%#<>{}|\^[]`"
 * to escape (or %NULL)
 *
 * This &percnt;-encodes the given URL part and returns the escaped version
 * in allocated memory, which the caller must free when it is done.
 *
 * Returns: the encoded string
 **/
gchar *
camel_url_encode (const gchar *part,
                  const gchar *escape_extra)
{
	GString *str;
	gchar *encoded;

	g_return_val_if_fail (part != NULL, NULL);

	str = g_string_new (NULL);
	append_url_encoded (str, part, escape_extra);
	encoded = str->str;
	g_string_free (str, FALSE);

	return encoded;
}

/**
 * camel_url_decode:
 * @part: a URL part
 *
 * &percnt;-decodes the passed-in URL *in place*. The decoded version is
 * never longer than the encoded version, so there does not need to
 * be any additional space at the end of the string.
 */
void
camel_url_decode (gchar *part)
{
	guchar *s, *d;

	g_return_if_fail (part != NULL);

#define XDIGIT(c) ((c) <= '9' ? (c) - '0' : ((c) & 0x4F) - 'A' + 10)

	s = d = (guchar *) part;
	do {
		if (*s == '%' && isxdigit (s[1]) && isxdigit (s[2])) {
			*d++ = (XDIGIT (s[1]) << 4) + XDIGIT (s[2]);
			s += 2;
		} else
			*d++ = *s;
	} while (*s++);
}

/**
 * camel_url_hash:
 * @u: the base URL
 *
 * Returns: the url hash
 */
guint
camel_url_hash (const CamelURL *u)
{
	guint hash = 0;

#define ADD_HASH(s) if (s) hash ^= g_str_hash (s);

	ADD_HASH (u->protocol);
	ADD_HASH (u->user);
	ADD_HASH (u->authmech);
	ADD_HASH (u->host);
	ADD_HASH (u->path);
	ADD_HASH (u->query);
	hash ^= u->port;

	return hash;
}

static gboolean
check_equal (gchar *s1,
             gchar *s2)
{
	if (s1 == NULL) {
		if (s2 == NULL)
			return TRUE;
		else
			return FALSE;
	}

	if (s2 == NULL)
		return FALSE;

	return strcmp (s1, s2) == 0;
}

/**
 * camel_url_equal:
 * @u: the base URL
 * @u2: the URL to compare
 *
 * Returns: return %TRUE if the two urls are equal
 */
gboolean
camel_url_equal (const CamelURL *u,
                 const CamelURL *u2)
{
	return check_equal (u->protocol, u2->protocol)
		&& check_equal (u->user, u2->user)
		&& check_equal (u->authmech, u2->authmech)
		&& check_equal (u->host, u2->host)
		&& check_equal (u->path, u2->path)
		&& check_equal (u->query, u2->query)
		&& u->port == u2->port;
}

/**
 * camel_url_copy:
 * @in: a #CamelURL to copy
 *
 * Copy a #CamelURL.
 *
 * Returns:(transfer full): a duplicate copy of @in
 **/
CamelURL *
camel_url_copy (CamelURL *in)
{
	CamelURL *out;

	g_return_val_if_fail (in != NULL, NULL);

	out = g_malloc0 (sizeof (*out));
	out->protocol = g_strdup (in->protocol);
	out->user = g_strdup (in->user);
	out->authmech = g_strdup (in->authmech);
	out->host = g_strdup (in->host);
	out->port = in->port;
	out->path = g_strdup (in->path);
	out->params = NULL;
	if (in->params)
		g_datalist_foreach (&((CamelURL *) in)->params, copy_param, &out->params);
	out->query = g_strdup (in->query);
	out->fragment = g_strdup (in->fragment);

	return out;
}

gchar *
camel_url_decode_path (const gchar *path)
{
	gchar **comps;
	GString *str;
	guint length, ii;

	if (path == NULL || *path == '\0')
		return g_strdup ("");    /* ??? or NULL? */

	str = g_string_new (NULL);

	comps = g_strsplit (path, "/", -1);
	length = g_strv_length (comps);

	for (ii = 0; ii < length; ii++) {
		if (ii > 0)
			g_string_append_c (str, '/');
		camel_url_decode (comps[ii]);
		g_string_append (str, comps[ii]);
	}

	g_strfreev (comps);

	return g_string_free (str, FALSE);
}

