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
 */

#if !defined (__CAMEL_H_INSIDE__) && !defined (CAMEL_COMPILATION)
#error "Only <camel/camel.h> can be included directly."
#endif

#ifndef CAMEL_SASL_PLAIN_H
#define CAMEL_SASL_PLAIN_H

#include <camel/camel-sasl.h>

/* Standard GObject macros */
#define CAMEL_TYPE_SASL_PLAIN \
	(camel_sasl_plain_get_type ())
#define CAMEL_SASL_PLAIN(obj) \
	(G_TYPE_CHECK_INSTANCE_CAST \
	((obj), CAMEL_TYPE_SASL_PLAIN, CamelSaslPlain))
#define CAMEL_SASL_PLAIN_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_CAST \
	((cls), CAMEL_TYPE_SASL_PLAIN, CamelSaslPlainClass))
#define CAMEL_IS_SASL_PLAIN(obj) \
	(G_TYPE_CHECK_INSTANCE_TYPE \
	((obj), CAMEL_TYPE_SASL_PLAIN))
#define CAMEL_IS_SASL_PLAIN_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_TYPE \
	((cls), CAMEL_TYPE_SASL_PLAIN))
#define CAMEL_SASL_PLAIN_GET_CLASS(obj) \
	(G_TYPE_INSTANCE_GET_CLASS \
	((obj), CAMEL_TYPE_SASL_PLAIN, CamelSaslPlainClass))

G_BEGIN_DECLS

typedef struct _CamelSaslPlain CamelSaslPlain;
typedef struct _CamelSaslPlainClass CamelSaslPlainClass;
typedef struct _CamelSaslPlainPrivate CamelSaslPlainPrivate;

struct _CamelSaslPlain {
	CamelSasl parent;
	CamelSaslPlainPrivate *priv;
};

struct _CamelSaslPlainClass {
	CamelSaslClass parent_class;

	/* Padding for future expansion */
	gpointer reserved[20];
};

GType camel_sasl_plain_get_type (void);

G_END_DECLS

#endif /* CAMEL_SASL_PLAIN_H */
