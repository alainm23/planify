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
 * Authors: Michael Zucchi <notzed@ximian.com>
 */

#if !defined (__CAMEL_H_INSIDE__) && !defined (CAMEL_COMPILATION)
#error "Only <camel/camel.h> can be included directly."
#endif

#ifndef CAMEL_MIME_FILTER_BASIC_H
#define CAMEL_MIME_FILTER_BASIC_H

#include <camel/camel-enums.h>
#include <camel/camel-mime-filter.h>

/* Standard GObject macros */
#define CAMEL_TYPE_MIME_FILTER_BASIC \
	(camel_mime_filter_basic_get_type ())
#define CAMEL_MIME_FILTER_BASIC(obj) \
	(G_TYPE_CHECK_INSTANCE_CAST \
	((obj), CAMEL_TYPE_MIME_FILTER_BASIC, CamelMimeFilterBasic))
#define CAMEL_MIME_FILTER_BASIC_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_CAST \
	((cls), CAMEL_TYPE_MIME_FILTER_BASIC, CamelMimeFilterBasicClass))
#define CAMEL_IS_MIME_FILTER_BASIC(obj) \
	(G_TYPE_CHECK_INSTANCE_TYPE \
	((obj), CAMEL_TYPE_MIME_FILTER_BASIC))
#define CAMEL_IS_MIME_FILTER_BASIC_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_TYPE \
	((cls), CAMEL_TYPE_MIME_FILTER_BASIC))
#define CAMEL_MIME_FILTER_BASIC_GET_CLASS(obj) \
	(G_TYPE_INSTANCE_GET_CLASS \
	((obj), CAMEL_TYPE_MIME_FILTER_BASIC, CamelMimeFilterBasicClass))

G_BEGIN_DECLS

typedef struct _CamelMimeFilterBasic CamelMimeFilterBasic;
typedef struct _CamelMimeFilterBasicClass CamelMimeFilterBasicClass;
typedef struct _CamelMimeFilterBasicPrivate CamelMimeFilterBasicPrivate;

struct _CamelMimeFilterBasic {
	CamelMimeFilter parent;
	CamelMimeFilterBasicPrivate *priv;
};

struct _CamelMimeFilterBasicClass {
	CamelMimeFilterClass parent_class;

	/* Padding for future expansion */
	gpointer reserved[20];
};

GType		camel_mime_filter_basic_get_type (void);
CamelMimeFilter *
		camel_mime_filter_basic_new	(CamelMimeFilterBasicType type);

G_END_DECLS

#endif /* CAMEL_MIME_FILTER_BASIC_H */
