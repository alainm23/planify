/* -*- Mode: C; tab-width: 8; indent-tabs-mode: t; c-basic-offset: 8 -*- */
/*
 * Copyright (C) 2017 Red Hat, Inc. (www.redhat.com)
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
 * SECTION: e-xml-document
 * @include: libedataserver/libedataserver.h
 * @short_description: An XML document wrapper
 *
 * The #EXmlDocument class wraps creation of XML documents.
 **/

#include "evolution-data-server-config.h"

#include <string.h>

#include "e-xml-document.h"

struct _EXmlDocumentPrivate {
	xmlDocPtr doc;
	xmlNodePtr root;
	xmlNodePtr current_element;

	GHashTable *namespaces_by_href; /* gchar *ns_href ~> xmlNsPtr */
};

G_DEFINE_TYPE (EXmlDocument, e_xml_document, G_TYPE_OBJECT)

static void
e_xml_document_finalize (GObject *object)
{
	EXmlDocument *xml = E_XML_DOCUMENT (object);

	if (xml->priv->doc) {
		xmlFreeDoc (xml->priv->doc);
		xml->priv->doc = NULL;
	}

	xml->priv->root = NULL;
	xml->priv->current_element = NULL;

	if (xml->priv->namespaces_by_href) {
		g_hash_table_destroy (xml->priv->namespaces_by_href);
		xml->priv->namespaces_by_href = NULL;
	}

	/* Chain up to parent's method. */
	G_OBJECT_CLASS (e_xml_document_parent_class)->finalize (object);
}

static void
e_xml_document_class_init (EXmlDocumentClass *klass)
{
	GObjectClass *object_class;

	g_type_class_add_private (klass, sizeof (EXmlDocumentPrivate));

	object_class = G_OBJECT_CLASS (klass);
	object_class->finalize = e_xml_document_finalize;
}

static void
e_xml_document_init (EXmlDocument *xml)
{
	xml->priv = G_TYPE_INSTANCE_GET_PRIVATE (xml, E_TYPE_XML_DOCUMENT, EXmlDocumentPrivate);

	xml->priv->doc = xmlNewDoc ((const xmlChar *) "1.0");
	g_return_if_fail (xml->priv->doc != NULL);

	xml->priv->doc->encoding = xmlCharStrdup ("UTF-8");

	xml->priv->namespaces_by_href = g_hash_table_new_full (g_str_hash, g_str_equal, g_free, NULL);
}

/**
 * e_xml_document_new:
 * @ns_href: (nullable): default namespace href to use, or %NULL
 * @root_element: root element name
 *
 * Creates a new #EXmlDocument with root element @root_element and optionally
 * also with set default namespace @ns_href.
 *
 * Returns: (transfer full): a new #EXmlDocument; free it with g_object_unref(),
 *    when no longer needed.
 *
 * Since: 3.26
 **/
EXmlDocument *
e_xml_document_new (const gchar *ns_href,
		    const gchar *root_element)
{
	EXmlDocument *xml;

	g_return_val_if_fail (root_element != NULL, NULL);
	g_return_val_if_fail (*root_element, NULL);

	xml = g_object_new (E_TYPE_XML_DOCUMENT, NULL);

	xml->priv->root = xmlNewDocNode (xml->priv->doc, NULL, (const xmlChar *) root_element, NULL);
	if (ns_href) {
		xmlNsPtr ns;

		ns = xmlNewNs (xml->priv->root, (const xmlChar *) ns_href, NULL);
		g_warn_if_fail (ns != NULL);

		xmlSetNs (xml->priv->root, ns);

		if (ns)
			g_hash_table_insert (xml->priv->namespaces_by_href, g_strdup (ns_href), ns);
	}

	xmlDocSetRootElement (xml->priv->doc, xml->priv->root);

	xml->priv->current_element = xml->priv->root;

	return xml;
}

/**
 * e_xml_document_get_xmldoc:
 * @xml: an #EXmlDocument
 *
 * Returns: (transfer none): Underlying #xmlDocPtr.
 *
 * Since: 3.26
 **/
xmlDoc *
e_xml_document_get_xmldoc (EXmlDocument *xml)
{
	g_return_val_if_fail (E_IS_XML_DOCUMENT (xml), NULL);

	return xml->priv->doc;
}

/**
 * e_xml_document_get_content:
 * @xml: an #EXmlDocument
 * @out_length: (out) (nullable): optional return location for length of the content, or %NULL
 *
 * Gets content of the @xml as string. The string is nul-terminated, but
 * if @out_length is also provided, then it doesn't contain this additional
 * nul character.
 *
 * Returns: (transfer full): Content of the @xml as newly allocated string.
 *    Free it with g_free(), when no longer needed.
 *
 * Since: 3.26
 **/
gchar *
e_xml_document_get_content (const EXmlDocument *xml,
			    gsize *out_length)
{
	xmlOutputBufferPtr xmlbuffer;
	gsize length;
	gchar *text;

	g_return_val_if_fail (E_IS_XML_DOCUMENT (xml), NULL);

	xmlbuffer = xmlAllocOutputBuffer (NULL);
	xmlNodeDumpOutput (xmlbuffer, xml->priv->doc, xml->priv->root, 0, 1, NULL);
	xmlOutputBufferFlush (xmlbuffer);

#ifdef LIBXML2_NEW_BUFFER
	length = xmlOutputBufferGetSize (xmlbuffer);
	text = g_strndup ((const gchar *) xmlOutputBufferGetContent (xmlbuffer), length);
#else
	length = xmlbuffer->buffer->use;
	text = g_strndup ((const gchar *) xmlbuffer->buffer->content, length);
#endif

	xmlOutputBufferClose (xmlbuffer);

	if (out_length)
		*out_length = length;

	return text;
}

/**
 * e_xml_document_add_namespaces:
 * @xml: an #EXmlDocument
 * @ns_prefix: namespace prefix to use for this namespace
 * @ns_href: namespace href
 * @...: %NULL-terminated pairs of (ns_prefix, ns_href)
 *
 * Adds one or more namespaces to @xml, which can be referenced
 * later by @ns_href. The caller should take care that neither
 * used @ns_prefix, nor @ns_href, is already used by @xml.
 *
 * Since: 3.26
 **/
void
e_xml_document_add_namespaces (EXmlDocument *xml,
			       const gchar *ns_prefix,
			       const gchar *ns_href,
			       ...)
{
	xmlNsPtr ns;
	va_list va;

	g_return_if_fail (E_IS_XML_DOCUMENT (xml));
	g_return_if_fail (ns_prefix != NULL);
	g_return_if_fail (xml->priv->root != NULL);

	if (!ns_href)
		ns_href = "";

	if (!g_hash_table_contains (xml->priv->namespaces_by_href, ns_href)) {
		ns = xmlNewNs (xml->priv->root, (const xmlChar *) ns_href, (const xmlChar *) ns_prefix);
		g_return_if_fail (ns != NULL);

		g_hash_table_insert (xml->priv->namespaces_by_href, g_strdup (ns_href), ns);
	}

	va_start (va, ns_href);

	while (ns_prefix = va_arg (va, const gchar *), ns_prefix) {
		ns_href = va_arg (va, const gchar *);
		if (!ns_href)
			ns_href = "";

		if (!g_hash_table_contains (xml->priv->namespaces_by_href, ns_href)) {
			ns = xmlNewNs (xml->priv->root, (const xmlChar *) ns_href, (const xmlChar *) ns_prefix);
			g_warn_if_fail (ns != NULL);

			if (ns)
				g_hash_table_insert (xml->priv->namespaces_by_href, g_strdup (ns_href), ns);
		}
	}

	va_end (va);
}

static gchar *
e_xml_document_number_to_alpha (gint number)
{
	GString *alpha;

	g_return_val_if_fail (number >= 0, NULL);

	alpha = g_string_new ("");
	g_string_append_c (alpha, 'A' + (number % 26));

	while (number = number / 26, number > 0) {
		g_string_prepend_c (alpha, 'A' + (number % 26));
	}

	return g_string_free (alpha, FALSE);
}

static gchar *
e_xml_document_gen_ns_prefix (EXmlDocument *xml,
			      const gchar *ns_href)
{
	GHashTable *prefixes;
	GHashTableIter iter;
	gpointer value;
	gchar *new_prefix = NULL;
	const gchar *ptr;
	gint counter = 0, n_prefixes;

	g_return_val_if_fail (E_IS_XML_DOCUMENT (xml), NULL);
	g_return_val_if_fail (ns_href && *ns_href, NULL);

	prefixes = g_hash_table_new (g_str_hash, g_str_equal);

	g_hash_table_iter_init (&iter, xml->priv->namespaces_by_href);
	while (g_hash_table_iter_next (&iter, NULL, &value)) {
		xmlNsPtr ns = value;

		if (ns && ns->prefix)
			g_hash_table_insert (prefixes, (gpointer) ns->prefix, NULL);
	}

	ptr = strrchr (ns_href, ':');

	/* the ns_href ends with ':' */
	if (ptr && !ptr[1] && g_ascii_isalpha (ns_href[0])) {
		new_prefix = g_strndup (ns_href, 1);
	} else if (ptr && strchr (ns_href, ':') < ptr && g_ascii_isalpha (ptr[1])) {
		new_prefix = g_strndup (ptr + 1, 1);
	} else if (g_str_has_prefix (ns_href, "http://") &&
		   g_ascii_isalpha (ns_href[7])) {
		new_prefix = g_strndup (ns_href + 7, 1);
	}

	n_prefixes = g_hash_table_size (prefixes);

	while (!new_prefix || g_hash_table_contains (prefixes, new_prefix)) {
		g_free (new_prefix);

		if (counter > n_prefixes + 2) {
			new_prefix = NULL;
			break;
		}

		new_prefix = e_xml_document_number_to_alpha (counter);
		counter++;
	}

	g_hash_table_destroy (prefixes);

	return new_prefix;
}

static xmlNsPtr
e_xml_document_ensure_namespace (EXmlDocument *xml,
				 const gchar *ns_href)
{
	xmlNsPtr ns;
	gchar *ns_prefix;

	g_return_val_if_fail (E_IS_XML_DOCUMENT (xml), NULL);

	if (!ns_href)
		return NULL;

	ns = g_hash_table_lookup (xml->priv->namespaces_by_href, ns_href);
	if (ns || !*ns_href)
		return ns;

	ns_prefix = e_xml_document_gen_ns_prefix (xml, ns_href);

	e_xml_document_add_namespaces (xml, ns_prefix, ns_href, NULL);

	g_free (ns_prefix);

	return g_hash_table_lookup (xml->priv->namespaces_by_href, ns_href);
}

/**
 * e_xml_document_start_element:
 * @xml: an #EXmlDocument
 * @ns_href: (nullable): optional namespace href for the new element, or %NULL
 * @name: name of the new element
 *
 * Starts a new non-text element as a child of the current element.
 * Each such call should be ended with corresponding e_xml_document_end_element().
 * Use %NULL @ns_href, to use the default namespace, otherwise either previously
 * added namespace with the same href from e_xml_document_add_namespaces() is picked,
 * or a new namespace with generated prefix is added.
 *
 * To start a text node use e_xml_document_start_text_element().
 *
 * Since: 3.26
 **/
void
e_xml_document_start_element (EXmlDocument *xml,
			      const gchar *ns_href,
			      const gchar *name)
{
	g_return_if_fail (E_IS_XML_DOCUMENT (xml));
	g_return_if_fail (name != NULL);
	g_return_if_fail (*name);
	g_return_if_fail (xml->priv->current_element != NULL);

	xml->priv->current_element = xmlNewChild (xml->priv->current_element,
		e_xml_document_ensure_namespace (xml, ns_href), (const xmlChar *) name, NULL);
}

/**
 * e_xml_document_start_text_element:
 * @xml: an #EXmlDocument
 * @ns_href: (nullable): optional namespace href for the new element, or %NULL
 * @name: name of the new element
 *
 * Starts a new text element as a child of the current element.
 * Each such call should be ended with corresponding e_xml_document_end_element().
 * Use %NULL @ns_href, to use the default namespace, otherwise either previously
 * added namespace with the same href from e_xml_document_add_namespaces() is picked,
 * or a new namespace with generated prefix is added.
 *
 * To start a non-text node use e_xml_document_start_element().
 *
 * Since: 3.26
 **/
void
e_xml_document_start_text_element (EXmlDocument *xml,
				   const gchar *ns_href,
				   const gchar *name)
{
	g_return_if_fail (E_IS_XML_DOCUMENT (xml));
	g_return_if_fail (name != NULL);
	g_return_if_fail (*name);
	g_return_if_fail (xml->priv->current_element != NULL);

	xml->priv->current_element = xmlNewTextChild (xml->priv->current_element,
		e_xml_document_ensure_namespace (xml, ns_href), (const xmlChar *) name, NULL);
}

/**
 * e_xml_document_end_element:
 * @xml: an #EXmlDocument
 *
 * This is a pair function for e_xml_document_start_element() and
 * e_xml_document_start_text_element(), which changes current
 * element to the parent of that element.
 *
 * Since: 3.26
 **/
void
e_xml_document_end_element (EXmlDocument *xml)
{
	g_return_if_fail (E_IS_XML_DOCUMENT (xml));
	g_return_if_fail (xml->priv->current_element != NULL);
	g_return_if_fail (xml->priv->current_element != xml->priv->root);

	xml->priv->current_element = xml->priv->current_element->parent;
}

/**
 * e_xml_document_add_empty_element:
 * @xml: an #EXmlDocument
 * @ns_href: (nullable): optional namespace href for the new element, or %NULL
 * @name: name of the new element
 *
 * Adds an empty element, which is an element with no attribute and no value.
 *
 * It's the same as calling e_xml_document_start_element() immediately
 * followed by e_xml_document_end_element().
 *
 * Since: 3.26
 **/
void
e_xml_document_add_empty_element (EXmlDocument *xml,
				  const gchar *ns_href,
				  const gchar *name)
{
	g_return_if_fail (E_IS_XML_DOCUMENT (xml));
	g_return_if_fail (name != NULL);
	g_return_if_fail (*name);
	g_return_if_fail (xml->priv->current_element != NULL);

	e_xml_document_start_element (xml, ns_href, name);
	e_xml_document_end_element (xml);
}

/**
 * e_xml_document_add_attribute:
 * @xml: an #EXmlDocument
 * @ns_href: (nullable): optional namespace href for the new attribute, or %NULL
 * @name: name of the attribute
 * @value: value of the attribute
 *
 * Adds a new attribute to the current element.
 * Use %NULL @ns_href, to use the default namespace, otherwise either previously
 * added namespace with the same href from e_xml_document_add_namespaces() is picked,
 * or a new namespace with generated prefix is added.
 *
 * Since: 3.26
 **/
void
e_xml_document_add_attribute (EXmlDocument *xml,
			      const gchar *ns_href,
			      const gchar *name,
			      const gchar *value)
{
	g_return_if_fail (E_IS_XML_DOCUMENT (xml));
	g_return_if_fail (xml->priv->current_element != NULL);
	g_return_if_fail (name != NULL);
	g_return_if_fail (value != NULL);

	xmlNewNsProp (
		xml->priv->current_element,
		e_xml_document_ensure_namespace (xml, ns_href),
		(const xmlChar *) name,
		(const xmlChar *) value);
}

/**
 * e_xml_document_add_attribute_int:
 * @xml: an #EXmlDocument
 * @ns_href: (nullable): optional namespace href for the new attribute, or %NULL
 * @name: name of the attribute
 * @value: integer value of the attribute
 *
 * Adds a new attribute with an integer value to the current element.
 * Use %NULL @ns_href, to use the default namespace, otherwise either previously
 * added namespace with the same href from e_xml_document_add_namespaces() is picked,
 * or a new namespace with generated prefix is added.
 *
 * Since: 3.26
 **/
void
e_xml_document_add_attribute_int (EXmlDocument *xml,
				  const gchar *ns_href,
				  const gchar *name,
				  gint64 value)
{
	gchar *strvalue;

	g_return_if_fail (E_IS_XML_DOCUMENT (xml));
	g_return_if_fail (xml->priv->current_element != NULL);
	g_return_if_fail (name != NULL);

	strvalue = g_strdup_printf ("%" G_GINT64_FORMAT, value);
	e_xml_document_add_attribute (xml, ns_href, name, strvalue);
	g_free (strvalue);
}

/**
 * e_xml_document_add_attribute_double:
 * @xml: an #EXmlDocument
 * @ns_href: (nullable): optional namespace href for the new attribute, or %NULL
 * @name: name of the attribute
 * @value: double value of the attribute
 *
 * Adds a new attribute with a double value to the current element.
 * Use %NULL @ns_href, to use the default namespace, otherwise either previously
 * added namespace with the same href from e_xml_document_add_namespaces() is picked,
 * or a new namespace with generated prefix is added.
 *
 * Since: 3.26
 **/
void
e_xml_document_add_attribute_double (EXmlDocument *xml,
				     const gchar *ns_href,
				     const gchar *name,
				     gdouble value)
{
	gchar *strvalue;

	g_return_if_fail (E_IS_XML_DOCUMENT (xml));
	g_return_if_fail (xml->priv->current_element != NULL);
	g_return_if_fail (name != NULL);

	strvalue = g_strdup_printf ("%f", value);
	e_xml_document_add_attribute (xml, ns_href, name, strvalue);
	g_free (strvalue);
}

/**
 * e_xml_document_add_attribute_time:
 * @xml: an #EXmlDocument
 * @ns_href: (nullable): optional namespace href for the new attribute, or %NULL
 * @name: name of the attribute
 * @value: time_t value of the attribute
 *
 * Adds a new attribute with a time_t value in ISO 8601 format to the current element.
 * The format is "YYYY-MM-DDTHH:MM:SSZ".
 * Use %NULL @ns_href, to use the default namespace, otherwise either previously
 * added namespace with the same href from e_xml_document_add_namespaces() is picked,
 * or a new namespace with generated prefix is added.
 *
 * Since: 3.26
 **/
void
e_xml_document_add_attribute_time (EXmlDocument *xml,
				   const gchar *ns_href,
				   const gchar *name,
				   time_t value)
{
	GTimeVal tv;
	gchar *strvalue;

	g_return_if_fail (E_IS_XML_DOCUMENT (xml));
	g_return_if_fail (xml->priv->current_element != NULL);
	g_return_if_fail (name != NULL);

	tv.tv_usec = 0;
	tv.tv_sec = value;

	strvalue = g_time_val_to_iso8601 (&tv);
	e_xml_document_add_attribute (xml, ns_href, name, strvalue);
	g_free (strvalue);
}

/**
 * e_xml_document_write_int:
 * @xml: an #EXmlDocument
 * @value: value to write as the content
 *
 * Writes @value as content of the current element.
 *
 * Since: 3.26
 **/
void
e_xml_document_write_int (EXmlDocument *xml,
			  gint64 value)
{
	gchar *strvalue;

	g_return_if_fail (E_IS_XML_DOCUMENT (xml));
	g_return_if_fail (xml->priv->current_element != NULL);

	strvalue = g_strdup_printf ("%" G_GINT64_FORMAT, value);
	e_xml_document_write_string (xml, strvalue);
	g_free (strvalue);
}

/**
 * e_xml_document_write_double:
 * @xml: an #EXmlDocument
 * @value: value to write as the content
 *
 * Writes @value as content of the current element.
 *
 * Since: 3.26
 **/
void
e_xml_document_write_double (EXmlDocument *xml,
			     gdouble value)
{
	gchar *strvalue;

	g_return_if_fail (E_IS_XML_DOCUMENT (xml));
	g_return_if_fail (xml->priv->current_element != NULL);

	strvalue = g_strdup_printf ("%f", value);
	e_xml_document_write_string (xml, strvalue);
	g_free (strvalue);
}

/**
 * e_xml_document_write_base64:
 * @xml: an #EXmlDocument
 * @value: value to write as the content
 * @len: length of @value
 *
 * Writes @value of length @len, encoded to base64, as content of the current element.
 *
 * Since: 3.26
 **/
void
e_xml_document_write_base64 (EXmlDocument *xml,
			     const gchar *value,
			     gint len)
{
	gchar *strvalue;

	g_return_if_fail (E_IS_XML_DOCUMENT (xml));
	g_return_if_fail (xml->priv->current_element != NULL);
	g_return_if_fail (value != NULL);

	strvalue = g_base64_encode ((const guchar *) value, len);
	e_xml_document_write_string (xml, strvalue);
	g_free (strvalue);
}

/**
 * e_xml_document_write_time:
 * @xml: an #EXmlDocument
 * @value: value to write as the content
 *
 * Writes @value in ISO 8601 format as content of the current element.
 * The format is "YYYY-MM-DDTHH:MM:SSZ".
 *
 * Since: 3.26
 **/
void
e_xml_document_write_time (EXmlDocument *xml,
			   time_t value)
{
	GTimeVal tv;
	gchar *strvalue;

	g_return_if_fail (E_IS_XML_DOCUMENT (xml));
	g_return_if_fail (xml->priv->current_element != NULL);

	tv.tv_usec = 0;
	tv.tv_sec = value;

	strvalue = g_time_val_to_iso8601 (&tv);
	e_xml_document_write_string (xml, strvalue);
	g_free (strvalue);
}

/**
 * e_xml_document_write_string:
 * @xml: an #EXmlDocument
 * @value: value to write as the content
 *
 * Writes @value as content of the current element.
 *
 * Since: 3.26
 **/
void
e_xml_document_write_string (EXmlDocument *xml,
			     const gchar *value)
{
	g_return_if_fail (E_IS_XML_DOCUMENT (xml));
	g_return_if_fail (xml->priv->current_element != NULL);
	g_return_if_fail (value != NULL);

	xmlNodeAddContent (
		xml->priv->current_element,
		(const xmlChar *) value);
}

/**
 * e_xml_document_write_buffer:
 * @xml: an #EXmlDocument
 * @value: value to write as the content
 * @len: length of @value
 *
 * Writes @value of length @len as content of the current element.
 *
 * Since: 3.26
 **/
void
e_xml_document_write_buffer (EXmlDocument *xml,
			     const gchar *value,
			     gint len)
{
	g_return_if_fail (E_IS_XML_DOCUMENT (xml));
	g_return_if_fail (xml->priv->current_element != NULL);
	g_return_if_fail (value != NULL);

	xmlNodeAddContentLen (
		xml->priv->current_element,
		(const xmlChar *) value, len);
}
