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
 */

#include "evolution-data-server-config.h"

#include <unistd.h>
#include <fcntl.h>
#include <errno.h>

#ifndef O_BINARY
#define O_BINARY 0
#endif

#include <libxml/parser.h>
#include <libxml/catalog.h>
#include <libxml/tree.h>
#include <libxml/xpathInternals.h>

#include <glib/gstdio.h>

#include "e-xml-utils.h"

#ifdef G_OS_WIN32
#define fsync(fd) 0
#endif

/**
 * e_xml_initialize_in_main: (skip)
 *
 * Initializes libxml library global memory. This should be called
 * in the main thread. The function does nothing, when it had been
 * called already.
 *
 * Since: 3.28
 **/
void
e_xml_initialize_in_main (void)
{
	static volatile guint called = 0;

	if (!g_atomic_int_or (&called, 1)) {
		xmlInitMemory ();
		xmlInitThreads ();
		xmlInitGlobals ();
		xmlInitializeCatalog ();
		xmlInitParser ();
	}
}

/**
 * e_xml_parse_file: (skip)
 * @filename: path to an XML file
 *
 * Reads a local XML file and parses the contents into an XML document
 * structure.  If the XML file cannot be read or its contents are malformed,
 * the function returns %NULL.
 *
 * Returns: (transfer full): an XML document structure, or %NULL
 **/
xmlDoc *
e_xml_parse_file (const gchar *filename)
{
	xmlDocPtr result = NULL;

	GMappedFile *mapped_file;

	mapped_file = g_mapped_file_new (filename, FALSE, NULL);
	if (mapped_file) {
		result = xmlParseMemory (
			g_mapped_file_get_contents (mapped_file),
			g_mapped_file_get_length (mapped_file));
		g_mapped_file_unref (mapped_file);
	}

	return result;
}

/**
 * e_xml_save_file:
 * @filename: path to a file to save to
 * @doc: an XML document structure
 *
 * Writes the given XML document structure to the file given by @filename.
 * If an error occurs while saving, the function returns -1 and sets errno.
 *
 * Returns: 0 on success, -1 on failure
 **/
gint
e_xml_save_file (const gchar *filename,
                 xmlDoc *doc)
{
	gchar *filesave;
	xmlChar *xmlbuf;
	gsize n, written = 0;
	gint ret, fd, size;
	gint errnosave;
	gssize w;
	gchar *dirname = g_path_get_dirname (filename);
	gchar *basename = g_path_get_basename (filename);
	gchar *savebasename = g_strconcat (".#", basename, NULL);

	g_free (basename);
	filesave = g_build_filename (dirname, savebasename, NULL);
	g_free (savebasename);
	g_free (dirname);

	fd = g_open (filesave, O_WRONLY | O_CREAT | O_TRUNC | O_BINARY, 0600);
	if (fd == -1) {
		g_free (filesave);
		return -1;
	}

	xmlDocDumpFormatMemory (doc, &xmlbuf, &size, TRUE);
	if (size <= 0) {
		close (fd);
		g_unlink (filesave);
		g_free (filesave);
		errno = ENOMEM;
		return -1;
	}

	n = (gsize) size;
	do {
		do {
			w = write (fd, xmlbuf + written, n - written);
		} while (w == -1 && errno == EINTR);

		if (w > 0)
			written += w;
	} while (w != -1 && written < n);

	xmlFree (xmlbuf);

	if (written < n || fsync (fd) == -1) {
		errnosave = errno;
		close (fd);
		g_unlink (filesave);
		g_free (filesave);
		errno = errnosave;
		return -1;
	}

	while ((ret = close (fd)) == -1 && errno == EINTR)
		;

	if (ret == -1) {
		g_free (filesave);
		return -1;
	}

	if (g_rename (filesave, filename) == -1) {
		errnosave = errno;
		g_unlink (filesave);
		g_free (filesave);
		errno = errnosave;
		return -1;
	}
	g_free (filesave);

	return 0;
}

/**
 * e_xml_get_child_by_name: (skip)
 * @parent: an XML node structure
 * @child_name: element name of a child node
 *
 * Attempts to find a child element of @parent named @child_name.
 * If no such child exists, the function returns %NULL.
 *
 * Returns: (nullable): a child XML node structure, or %NULL
 **/
xmlNode *
e_xml_get_child_by_name (const xmlNode *parent,
                         const xmlChar *child_name)
{
	xmlNode *child;

	g_return_val_if_fail (parent != NULL, NULL);
	g_return_val_if_fail (child_name != NULL, NULL);

	for (child = parent->xmlChildrenNode; child != NULL; child = child->next) {
		if (xmlStrcmp (child->name, child_name) == 0) {
			return child;
		}
	}
	return NULL;
}

/**
 * e_xml_parse_data: (skip)
 * @data: (array length=length) (element-type guint8): an XML data
 * @length: length of data, should be greated than zero
 *
 * Parses XML data into an #xmlDocPtr. Free returned pointer
 * with xmlFreeDoc(), when no longer needed.
 *
 * Returns: (nullable) (transfer full): a new #xmlDocPtr with parsed @data,
 *    or %NULL on error.
 *
 * Since: 3.26
 **/
xmlDoc *
e_xml_parse_data (gconstpointer data,
		  gsize length)
{
	g_return_val_if_fail (data != NULL, NULL);
	g_return_val_if_fail (length > 0, NULL);

	return xmlReadMemory (data, length, "data.xml", NULL, XML_PARSE_NOWARNING);
}

/**
 * e_xml_new_xpath_context_with_namespaces: (skip)
 * @doc: an #xmlDocPtr
 * @...: %NULL-terminated list of pairs (prefix, href) with namespaces
 *
 * Creates a new #xmlXPathContextPtr on @doc with preregistered
 * namespaces. The namepsaces are pair of (prefix, href), terminated
 * by %NULL.
 *
 * Returns: (transfer full): a new #xmlXPathContextPtr. Free the returned
 *    pointer with xmlXPathFreeContext() when no longer needed.
 *
 * Since: 3.26
 **/
xmlXPathContext *
e_xml_new_xpath_context_with_namespaces (xmlDoc *doc,
					 ...)
{
	xmlXPathContextPtr xpath_ctx;
	va_list va;
	const gchar *prefix;

	g_return_val_if_fail (doc != NULL, NULL);

	xpath_ctx = xmlXPathNewContext (doc);
	g_return_val_if_fail (xpath_ctx != NULL, NULL);

	va_start (va, doc);

	while (prefix = va_arg (va, const gchar *), prefix) {
		const gchar *href = va_arg (va, const gchar *);

		if (!href) {
			g_warn_if_fail (href != NULL);
			break;
		}

		xmlXPathRegisterNs (xpath_ctx, (const xmlChar *) prefix, (const xmlChar *) href);
	}

	va_end (va);

	return xpath_ctx;
}

/**
 * e_xml_xpath_context_register_namespaces: (skip)
 * @xpath_ctx: an #xmlXPathContextPtr
 * @prefix: namespace prefix
 * @href: namespace href
 * @...: %NULL-terminated list of pairs (prefix, href) with additional namespaces
 *
 * Registers one or more additional namespaces. It's a caller's error
 * to try to register a namespace with the same prefix again, unless
 * the prefix uses the same namespace href.
 *
 * Since: 3.26
 **/
void
e_xml_xpath_context_register_namespaces (xmlXPathContext *xpath_ctx,
					 const gchar *prefix,
					 const gchar *href,
					 ...)
{
	va_list va;
	const gchar *used_href;

	g_return_if_fail (xpath_ctx != NULL);
	g_return_if_fail (prefix != NULL);
	g_return_if_fail (href != NULL);

	used_href = (const gchar *) xmlXPathNsLookup (xpath_ctx, (const xmlChar *) prefix);
	if (used_href && g_strcmp0 (used_href, href) != 0) {
		g_warning ("%s: Trying to register prefix '%s' with href '%s', but it already points to '%s'",
			G_STRFUNC, prefix, href, used_href);
	} else if (!used_href) {
		xmlXPathRegisterNs (xpath_ctx, (const xmlChar *) prefix, (const xmlChar *) href);
	}

	va_start (va, href);

	while (prefix = va_arg (va, const gchar *), prefix) {
		href = va_arg (va, const gchar *);

		if (!href) {
			g_warn_if_fail (href != NULL);
			break;
		}

		used_href = (const gchar *) xmlXPathNsLookup (xpath_ctx, (const xmlChar *) prefix);
		if (used_href && g_strcmp0 (used_href, href) != 0) {
			g_warning ("%s: Trying to register prefix '%s' with href '%s', but it already points to '%s'",
				G_STRFUNC, prefix, href, used_href);
		} else if (!used_href) {
			xmlXPathRegisterNs (xpath_ctx, (const xmlChar *) prefix, (const xmlChar *) href);
		}
	}

	va_end (va);
}

/**
 * e_xml_xpath_eval: (skip)
 * @xpath_ctx: an #xmlXPathContextPtr
 * @format: printf-like format specifier of path to evaluate
 * @...: arguments for the @format
 *
 * Evaluates path specified by @format and returns its #xmlXPathObjectPtr,
 * in case the path evaluates to a non-empty node set. See also
 * e_xml_xpath_eval_as_string() which evaluates the path to string.
 *
 * Returns: (nullable) (transfer full): a new #xmlXPathObjectPtr which
 *    references given path, or %NULL if path cannot be found or when
 *    it evaluates to an empty nodeset. Free returned pointer with
 *    xmlXPathFreeObject(), when no longer needed.
 *
 * Since: 3.26
 **/
xmlXPathObject *
e_xml_xpath_eval (xmlXPathContext *xpath_ctx,
		  const gchar *format,
		  ...)
{
	xmlXPathObjectPtr object;
	va_list va;
	gchar *expr;

	g_return_val_if_fail (xpath_ctx != NULL, NULL);
	g_return_val_if_fail (format != NULL, NULL);

	va_start (va, format);
	expr = g_strdup_vprintf (format, va);
	va_end (va);

	object = xmlXPathEvalExpression ((const xmlChar *) expr, xpath_ctx);
	g_free (expr);

	if (!object)
		return NULL;

	if (object->type == XPATH_NODESET &&
	    xmlXPathNodeSetIsEmpty (object->nodesetval)) {
		xmlXPathFreeObject (object);
		return NULL;
	}

	return object;
}

/**
 * e_xml_xpath_eval_as_string: (skip)
 * @xpath_ctx: an #xmlXPathContextPtr
 * @format: printf-like format specifier of path to evaluate
 * @...: arguments for the @format
 *
 * Evaluates path specified by @format and returns its result as string,
 * in case the path evaluates to a non-empty node set. See also
 * e_xml_xpath_eval() which evaluates the path to an #xmlXPathObjectPtr.
 *
 * Returns: (nullable) (transfer full): a new string which contains value
 *    of the given path, or %NULL if path cannot be found or when
 *    it evaluates to an empty nodeset. Free returned pointer with
 *    g_free(), when no longer needed.
 *
 * Since: 3.26
 **/
gchar *
e_xml_xpath_eval_as_string (xmlXPathContext *xpath_ctx,
			    const gchar *format,
			    ...)
{
	xmlXPathObjectPtr object;
	va_list va;
	gchar *expr, *value;

	g_return_val_if_fail (xpath_ctx != NULL, NULL);
	g_return_val_if_fail (format != NULL, NULL);

	va_start (va, format);
	expr = g_strdup_vprintf (format, va);
	va_end (va);

	if (!g_str_has_prefix (format, "string(")) {
		gchar *tmp = expr;

		expr = g_strconcat ("string(", expr, ")", NULL);

		g_free (tmp);
	}

	object = e_xml_xpath_eval (xpath_ctx, "%s", expr);
	g_free (expr);

	if (!object)
		return NULL;

	if (object->type == XPATH_STRING &&
	    *object->stringval)
		value = g_strdup ((const gchar *) object->stringval);
	else
		value = NULL;

	xmlXPathFreeObject (object);

	return value;
}

/**
 * e_xml_xpath_eval_exists: (skip)
 * @xpath_ctx: an #xmlXPathContextPtr
 * @format: printf-like format specifier of path to evaluate
 * @...: arguments for the @format
 *
 * Evaluates path specified by @format and returns whether it exists.
 *
 * Returns: %TRUE, when the given XPath exists, %FALSE otherwise.
 *
 * Since: 3.26
 **/
gboolean
e_xml_xpath_eval_exists (xmlXPathContext *xpath_ctx,
			 const gchar *format,
			 ...)
{
	xmlXPathObjectPtr object;
	va_list va;
	gchar *expr;

	g_return_val_if_fail (xpath_ctx != NULL, FALSE);
	g_return_val_if_fail (format != NULL, FALSE);

	va_start (va, format);
	expr = g_strdup_vprintf (format, va);
	va_end (va);

	object = e_xml_xpath_eval (xpath_ctx, "%s", expr);
	g_free (expr);

	if (!object)
		return FALSE;

	xmlXPathFreeObject (object);

	return TRUE;
}
