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

#ifndef CAMEL_MESSAGE_INFO_BASE_H
#define CAMEL_MESSAGE_INFO_BASE_H

#include <glib-object.h>

#include <camel/camel-message-info.h>

/* Standard GObject macros */
#define CAMEL_TYPE_MESSAGE_INFO_BASE \
	(camel_message_info_base_get_type ())
#define CAMEL_MESSAGE_INFO_BASE(obj) \
	(G_TYPE_CHECK_INSTANCE_CAST \
	((obj), CAMEL_TYPE_MESSAGE_INFO_BASE, CamelMessageInfoBase))
#define CAMEL_MESSAGE_INFO_BASE_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_CAST \
	((cls), CAMEL_TYPE_MESSAGE_INFO_BASE, CamelMessageInfoBaseClass))
#define CAMEL_IS_MESSAGE_INFO_BASE(obj) \
	(G_TYPE_CHECK_INSTANCE_TYPE \
	((obj), CAMEL_TYPE_MESSAGE_INFO_BASE))
#define CAMEL_IS_MESSAGE_INFO_BASE_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_TYPE \
	((cls), CAMEL_TYPE_MESSAGE_INFO_BASE))
#define CAMEL_MESSAGE_INFO_BASE_GET_CLASS(obj) \
	(G_TYPE_INSTANCE_GET_CLASS \
	((obj), CAMEL_TYPE_MESSAGE_INFO_BASE, CamelMessageInfoBaseClass))

G_BEGIN_DECLS

typedef struct _CamelMessageInfoBase CamelMessageInfoBase;
typedef struct _CamelMessageInfoBaseClass CamelMessageInfoBaseClass;
typedef struct _CamelMessageInfoBasePrivate CamelMessageInfoBasePrivate;

struct _CamelMessageInfoBase {
	CamelMessageInfo parent;
	CamelMessageInfoBasePrivate *priv;
};

struct _CamelMessageInfoBaseClass {
	CamelMessageInfoClass parent_class;

	/* Padding for future expansion */
	gpointer reserved[20];
};

GType		camel_message_info_base_get_type	(void);

G_END_DECLS

#endif /* CAMEL_MESSAGE_INFO_BASE_H */
