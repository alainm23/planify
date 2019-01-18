/* -*- Mode: C; tab-width: 8; indent-tabs-mode: t; c-basic-offset: 8 -*-
 *
 * Copyright (C) 2012-2017 Matthias Klumpp <matthias@tenstral.net>
 *
 * Licensed under the GNU Lesser General Public License Version 2.1
 *
 * This library is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, either version 2.1 of the license, or
 * (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this library.  If not, see <http://www.gnu.org/licenses/>.
 */

#if !defined (__APPSTREAM_H) && !defined (AS_COMPILATION)
#error "Only <appstream.h> can be included directly."
#endif

#ifndef __AS_XML_H
#define __AS_XML_H

#include <libxml/tree.h>
#include <libxml/parser.h>
#include <libxml/xmlsave.h>
#include "as-context.h"
#include "as-tag.h"

G_BEGIN_DECLS
#pragma GCC visibility push(hidden)

gchar		*as_xml_get_node_value (xmlNode *node);
gchar		*as_xmldata_get_node_locale (AsContext *ctx,
					     xmlNode *node);

void		as_xml_add_children_values_to_array (xmlNode *node,
						     const gchar *element_name,
						     GPtrArray *array);

GPtrArray	*as_xml_get_children_as_string_list (xmlNode *node,
					       const gchar *element_name);
gchar		**as_xml_get_children_as_strv (xmlNode *node,
					       const gchar *element_name);

void		as_xml_parse_metainfo_description_node (AsContext *ctx,
							xmlNode *node,
							GHFunc func,
							gpointer entity);

gchar		*as_xml_dump_node_children (xmlNode *node);

void		as_xml_add_description_node (AsContext *ctx,
					     xmlNode *root,
					     GHashTable *desc_table);

void		as_xml_add_localized_text_node (xmlNode *root,
						const gchar *node_name,
						GHashTable *value_table);

xmlNode		*as_xml_add_node_list_strv (xmlNode *root,
						const gchar *name,
						const gchar *child_name,
						gchar **strv);

void		as_xml_add_node_list (xmlNode *root,
					const gchar *name,
					const gchar *child_name,
					GPtrArray *array);

xmlNode		*as_xml_add_text_node (xmlNode *root,
				       const gchar *name,
					const gchar *value);

xmlDoc		*as_xml_parse_document (const gchar *data,
					GError **error);

gchar		*as_xml_node_to_str (xmlNode *root, GError **error);

#pragma GCC visibility pop
G_END_DECLS

#endif /* __AS_XML_H */
