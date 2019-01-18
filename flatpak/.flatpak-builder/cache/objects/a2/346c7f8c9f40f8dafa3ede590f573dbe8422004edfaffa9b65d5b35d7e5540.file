/* -*- Mode: C; tab-width: 8; indent-tabs-mode: t; c-basic-offset: 8 -*- */
/*
 * Copyright (C) 2016 Red Hat, Inc. (www.redhat.com)
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

#if !defined (__CAMEL_H_INSIDE__) && !defined (CAMEL_COMPILATION)
#error "Only <camel/camel.h> can be included directly."
#endif

#ifndef CAMEL_NAME_VALUE_ARRAY_H
#define CAMEL_NAME_VALUE_ARRAY_H

#include <glib-object.h>
#include <camel/camel-enums.h>

G_BEGIN_DECLS

/**
 * CamelNameValueArray:
 *
 * Since: 3.24
 **/
struct _CamelNameValueArray;
typedef struct _CamelNameValueArray CamelNameValueArray;

#define CAMEL_TYPE_NAME_VALUE_ARRAY (camel_name_value_array_get_type ())

GType           camel_name_value_array_get_type	(void) G_GNUC_CONST;
CamelNameValueArray *
		camel_name_value_array_new	(void);
CamelNameValueArray *
		camel_name_value_array_new_sized
						(guint reserve_size);
CamelNameValueArray *
		camel_name_value_array_copy	(const CamelNameValueArray *array);
void		camel_name_value_array_free	(CamelNameValueArray *array);
guint		camel_name_value_array_get_length
						(const CamelNameValueArray *array);
gboolean	camel_name_value_array_get	(const CamelNameValueArray *array,
						 guint index,
						 const gchar **out_name,
						 const gchar **out_value);
const gchar *	camel_name_value_array_get_named
						(const CamelNameValueArray *array,
						 CamelCompareType compare_type,
						 const gchar *name);
const gchar *	camel_name_value_array_get_name	(const CamelNameValueArray *array,
						 guint index);
const gchar *	camel_name_value_array_get_value
						(const CamelNameValueArray *array,
						 guint index);
void		camel_name_value_array_append	(CamelNameValueArray *array,
						 const gchar *name,
						 const gchar *value);
gboolean	camel_name_value_array_set	(CamelNameValueArray *array,
						 guint index,
						 const gchar *name,
						 const gchar *value);
gboolean	camel_name_value_array_set_name	(CamelNameValueArray *array,
						 guint index,
						 const gchar *name);
gboolean	camel_name_value_array_set_value
						(CamelNameValueArray *array,
						 guint index,
						 const gchar *value);
gboolean	camel_name_value_array_set_named
						(CamelNameValueArray *array,
						 CamelCompareType compare_type,
						 const gchar *name,
						 const gchar *value);
gboolean	camel_name_value_array_remove	(CamelNameValueArray *array,
						 guint index);
guint		camel_name_value_array_remove_named
						(CamelNameValueArray *array,
						 CamelCompareType compare_type,
						 const gchar *name,
						 gboolean all_occurrences);
void		camel_name_value_array_clear	(CamelNameValueArray *array);
gboolean	camel_name_value_array_equal	(const CamelNameValueArray *array_a,
						 const CamelNameValueArray *array_b,
						 CamelCompareType compare_type);

G_END_DECLS

#endif /* CAMEL_NAME_VALUE_ARRAY_H */
