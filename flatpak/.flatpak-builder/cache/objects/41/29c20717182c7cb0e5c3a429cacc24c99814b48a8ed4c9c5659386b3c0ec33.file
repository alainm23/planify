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

#if !defined (__LIBEDATASERVER_H_INSIDE__) && !defined (LIBEDATASERVER_COMPILATION)
#error "Only <libedataserver/libedataserver.h> should be included directly."
#endif

#ifndef E_XML_DOCUMENT_H
#define E_XML_DOCUMENT_H

#include <glib.h>
#include <glib-object.h>
#include <libxml/parser.h>

/* Standard GObject macros */
#define E_TYPE_XML_DOCUMENT \
	(e_xml_document_get_type ())
#define E_XML_DOCUMENT(obj) \
	(G_TYPE_CHECK_INSTANCE_CAST \
	((obj), E_TYPE_XML_DOCUMENT, EXmlDocument))
#define E_XML_DOCUMENT_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_CAST \
	((cls), E_TYPE_XML_DOCUMENT, EXmlDocumentClass))
#define E_IS_XML_DOCUMENT(obj) \
	(G_TYPE_CHECK_INSTANCE_TYPE \
	((obj), E_TYPE_XML_DOCUMENT))
#define E_IS_XML_DOCUMENT_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_TYPE \
	((cls), E_TYPE_XML_DOCUMENT))
#define E_XML_DOCUMENT_GET_CLASS(obj) \
	(G_TYPE_INSTANCE_GET_CLASS \
	((obj), E_TYPE_XML_DOCUMENT, EXmlDocumentClass))

G_BEGIN_DECLS

typedef struct _EXmlDocument EXmlDocument;
typedef struct _EXmlDocumentClass EXmlDocumentClass;
typedef struct _EXmlDocumentPrivate EXmlDocumentPrivate;

/**
 * EXmlDocument:
 *
 * Contains only private data that should be read and manipulated using the
 * functions below.
 *
 * Since: 3.26
 **/
struct _EXmlDocument {
	/*< private >*/
	GObject parent;
	EXmlDocumentPrivate *priv;
};

struct _EXmlDocumentClass {
	GObjectClass parent_class;

	/* Padding for future expansion */
	gpointer reserved[10];
};

GType		e_xml_document_get_type		(void) G_GNUC_CONST;

EXmlDocument *	e_xml_document_new		(const gchar *ns_href,
						 const gchar *root_element);
xmlDoc *	e_xml_document_get_xmldoc	(EXmlDocument *xml);
gchar *		e_xml_document_get_content	(const EXmlDocument *xml,
						 gsize *out_length);
void		e_xml_document_add_namespaces	(EXmlDocument *xml,
						 const gchar *ns_prefix,
						 const gchar *ns_href,
						 ...) G_GNUC_NULL_TERMINATED;
void		e_xml_document_start_element	(EXmlDocument *xml,
						 const gchar *ns_href,
						 const gchar *name);
void		e_xml_document_start_text_element
						(EXmlDocument *xml,
						 const gchar *ns_href,
						 const gchar *name);
void		e_xml_document_end_element	(EXmlDocument *xml);
void		e_xml_document_add_empty_element
						(EXmlDocument *xml,
						 const gchar *ns_href,
						 const gchar *name);
void		e_xml_document_add_attribute	(EXmlDocument *xml,
						 const gchar *ns_href,
						 const gchar *name,
						 const gchar *value);
void		e_xml_document_add_attribute_int
						(EXmlDocument *xml,
						 const gchar *ns_href,
						 const gchar *name,
						 gint64 value);
void		e_xml_document_add_attribute_double
						(EXmlDocument *xml,
						 const gchar *ns_href,
						 const gchar *name,
						 gdouble value);
void		e_xml_document_add_attribute_time
						(EXmlDocument *xml,
						 const gchar *ns_href,
						 const gchar *name,
						 time_t value);
void		e_xml_document_write_int	(EXmlDocument *xml,
						 gint64 value);
void		e_xml_document_write_double	(EXmlDocument *xml,
						 gdouble value);
void		e_xml_document_write_base64	(EXmlDocument *xml,
						 const gchar *value,
						 gint len);
void		e_xml_document_write_time	(EXmlDocument *xml,
						 time_t value);
void		e_xml_document_write_string	(EXmlDocument *xml,
						 const gchar *value);
void		e_xml_document_write_buffer	(EXmlDocument *xml,
						 const gchar *value,
						 gint len);

G_END_DECLS

#endif /* E_XML_DOCUMENT_H */
