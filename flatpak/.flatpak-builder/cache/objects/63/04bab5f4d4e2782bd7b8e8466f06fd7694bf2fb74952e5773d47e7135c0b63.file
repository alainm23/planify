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

#ifndef CAMEL_NAMED_FLAGS_H
#define CAMEL_NAMED_FLAGS_H

#include <glib-object.h>

G_BEGIN_DECLS

/**
 * CamelNamedFlags:
 *
 * Since: 3.24
 **/
struct _CamelNamedFlags;
typedef struct _CamelNamedFlags CamelNamedFlags;

#define CAMEL_TYPE_NAMED_FLAGS (camel_named_flags_get_type ())

GType           camel_named_flags_get_type	(void) G_GNUC_CONST;
CamelNamedFlags *
		camel_named_flags_new		(void);
CamelNamedFlags *
		camel_named_flags_new_sized	(guint reserve_size);
CamelNamedFlags *
		camel_named_flags_copy		(const CamelNamedFlags *named_flags);
void		camel_named_flags_free		(CamelNamedFlags *named_flags);
gboolean	camel_named_flags_insert	(CamelNamedFlags *named_flags,
						 const gchar *name);
gboolean	camel_named_flags_remove	(CamelNamedFlags *named_flags,
						 const gchar *name);
gboolean	camel_named_flags_contains	(const CamelNamedFlags *named_flags,
						 const gchar *name);
void		camel_named_flags_clear		(CamelNamedFlags *named_flags);
guint		camel_named_flags_get_length	(const CamelNamedFlags *named_flags);
const gchar *	camel_named_flags_get		(const CamelNamedFlags *named_flags,
						 guint index);
gboolean	camel_named_flags_equal		(const CamelNamedFlags *named_flags_a,
						 const CamelNamedFlags *named_flags_b);

G_END_DECLS

#endif /* CAMEL_NAMED_FLAGS_H */
