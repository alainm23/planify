/* -*- Mode: C; tab-width: 8; indent-tabs-mode: t; c-basic-offset: 8 -*- */
/* camel-object.h: Base class for Camel
 *
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
 * Authors: Dan Winship <danw@ximian.com>
 *          Michael Zucchi <notzed@ximian.com>
 */

#if !defined (__CAMEL_H_INSIDE__) && !defined (CAMEL_COMPILATION)
#error "Only <camel/camel.h> can be included directly."
#endif

#ifndef CAMEL_OBJECT_H
#define CAMEL_OBJECT_H

#include <stdio.h>		/* FILE */
#include <stdlib.h>		/* gsize */
#include <stdarg.h>
#include <gio/gio.h>

/* Standard GObject macros */
#define CAMEL_TYPE_OBJECT \
	(camel_object_get_type ())
#define CAMEL_OBJECT(obj) \
	(G_TYPE_CHECK_INSTANCE_CAST \
	((obj), CAMEL_TYPE_OBJECT, CamelObject))
#define CAMEL_OBJECT_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_CAST \
	((cls), CAMEL_TYPE_OBJECT, CamelObjectClass))
#define CAMEL_IS_OBJECT(obj) \
	(G_TYPE_CHECK_INSTANCE_TYPE \
	((obj), CAMEL_TYPE_OBJECT))
#define CAMEL_IS_OBJECT_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_TYPE \
	((cls), CAMEL_TYPE_OBJECT))
#define CAMEL_OBJECT_GET_CLASS(obj) \
	(G_TYPE_INSTANCE_GET_CLASS \
	((obj), CAMEL_TYPE_OBJECT, CamelObjectClass))

/**
 * CAMEL_ERROR:
 *
 * Since: 2.32
 **/
#define CAMEL_ERROR \
	(camel_error_quark ())

G_BEGIN_DECLS

typedef struct _CamelObject CamelObject;
typedef struct _CamelObjectClass CamelObjectClass;
typedef struct _CamelObjectPrivate CamelObjectPrivate;

/**
 * CamelParamFlags:
 * @CAMEL_PARAM_PERSISTENT:
 *     The parameter is persistent, which means its value is saved to
 *     #CamelObject:state-filename during camel_object_state_write(),
 *     and restored during camel_object_state_read().
 *
 * These flags extend #GParamFlags.  Most of the time you will use them
 * in conjunction with g_object_class_install_property().
 *
 * Since: 2.32
 **/
typedef enum {
	CAMEL_PARAM_PERSISTENT = 1 << (G_PARAM_USER_SHIFT + 0)
} CamelParamFlags;

/**
 * CamelError:
 * @CAMEL_ERROR_GENERIC: a generic (fallback) error code
 *
 * Since: 2.32
 **/
typedef enum {
	CAMEL_ERROR_GENERIC		/* lazy fallback error */
} CamelError;

struct _CamelObject {
	GObject parent;
	CamelObjectPrivate *priv;
};

struct _CamelObjectClass {
	GObjectClass parent_class;

	gint		(*state_read)		(CamelObject *object,
						 FILE *fp);
	gint		(*state_write)		(CamelObject *object,
						 FILE *fp);

	/* Padding for future expansion */
	gpointer reserved[20];
};

GType		camel_object_get_type		(void);
GQuark		camel_error_quark		(void) G_GNUC_CONST;
gint		camel_object_state_read		(CamelObject *object);
gint		camel_object_state_write	(CamelObject *object);
const gchar *	camel_object_get_state_filename	(CamelObject *object);
void		camel_object_set_state_filename	(CamelObject *object,
						 const gchar *state_filename);

G_END_DECLS

#endif /* CAMEL_OBJECT_H */
