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
 * Authors: Michael Zucchi <notzed@ximian.com>
 */

/* WARNING
 *
 * DO NOT USE THIS CODE OUTSIDE OF CAMEL
 *
 * IT IS SUBJECT TO CHANGE OR MAY VANISH AT ANY TIME
 */

#if !defined (__CAMEL_H_INSIDE__) && !defined (CAMEL_COMPILATION)
#error "Only <camel/camel.h> can be included directly."
#endif

#ifndef CAMEL_HTML_PARSER_H
#define CAMEL_HTML_PARSER_H

#include <glib-object.h>

/* Standard GObject macros */
#define CAMEL_TYPE_HTML_PARSER \
	(camel_html_parser_get_type ())
#define CAMEL_HTML_PARSER(obj) \
	(G_TYPE_CHECK_INSTANCE_CAST \
	((obj), CAMEL_TYPE_HTML_PARSER, CamelHTMLParser))
#define CAMEL_HTML_PARSER_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_CAST \
	((cls), CAMEL_TYPE_HTML_PARSER, CamelHTMLParserClass))
#define CAMEL_IS_HTML_PARSER(obj) \
	(G_TYPE_CHECK_INSTANCE_TYPE \
	((obj), CAMEL_TYPE_HTML_PARSER))
#define CAMEL_IS_HTML_PARSER_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_TYPE \
	((cls), CAMEL_TYPE_HTML_PARSER))
#define CAMEL_HTML_PARSER_GET_CLASS(obj) \
	(G_TYPE_INSTANCE_GET_CLASS \
	((obj), CAMEL_TYPE_HTML_PARSER, CamelHTMLParserClass))

G_BEGIN_DECLS

typedef struct _CamelHTMLParser CamelHTMLParser;
typedef struct _CamelHTMLParserClass CamelHTMLParserClass;
typedef struct _CamelHTMLParserPrivate CamelHTMLParserPrivate;

/* Parser/tokeniser states */
typedef enum _camel_html_parser_t {
	CAMEL_HTML_PARSER_DATA,			/* raw data */
	CAMEL_HTML_PARSER_ENT,			/* entity in data */
	CAMEL_HTML_PARSER_ELEMENT,		/* element (tag + attributes scanned) */
	CAMEL_HTML_PARSER_TAG,			/* tag */
	CAMEL_HTML_PARSER_DTDENT,		/* dtd entity? <! blah blah > */
	CAMEL_HTML_PARSER_COMMENT0,		/* start of comment */
	CAMEL_HTML_PARSER_COMMENT,		/* body of comment */
	CAMEL_HTML_PARSER_ATTR0,		/* start of attribute */
	CAMEL_HTML_PARSER_ATTR,			/* attribute */
	CAMEL_HTML_PARSER_VAL0,			/* start of value */
	CAMEL_HTML_PARSER_VAL,			/* value */
	CAMEL_HTML_PARSER_VAL_ENT,		/* entity in value */
	CAMEL_HTML_PARSER_EOD,			/* end of current data */
	CAMEL_HTML_PARSER_EOF			/* end of file */
} CamelHTMLParserState;

struct _CamelHTMLParser {
	GObject parent;
	CamelHTMLParserPrivate *priv;
};

struct _CamelHTMLParserClass {
	GObjectClass parent_class;

	/* Padding for future expansion */
	gpointer reserved[20];
};

GType		camel_html_parser_get_type	(void);
CamelHTMLParser      *camel_html_parser_new	(void);

void camel_html_parser_set_data (CamelHTMLParser *hp, const gchar *start, gint len, gint last);
CamelHTMLParserState camel_html_parser_step (CamelHTMLParser *hp, const gchar **datap, gint *lenp);
const gchar *camel_html_parser_left (CamelHTMLParser *hp, gint *lenp);
const gchar *camel_html_parser_tag (CamelHTMLParser *hp);
const gchar *camel_html_parser_attr (CamelHTMLParser *hp, const gchar *name);
const GPtrArray *camel_html_parser_attr_list (CamelHTMLParser *hp, const GPtrArray **values);

G_END_DECLS

#endif /* CAMEL_HTML_PARSER_H */
