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
 * Authors: David Woodhouse <dwmw2@infradead.org>
 */

#if !defined (__CAMEL_H_INSIDE__) && !defined (CAMEL_COMPILATION)
#error "Only <camel/camel.h> can be included directly."
#endif

#ifndef CAMEL_STREAM_PROCESS_H
#define CAMEL_STREAM_PROCESS_H

#include <camel/camel-stream.h>

/* Standard GObject macros */
#define CAMEL_TYPE_STREAM_PROCESS \
	(camel_stream_process_get_type ())
#define CAMEL_STREAM_PROCESS(obj) \
	(G_TYPE_CHECK_INSTANCE_CAST \
	((obj), CAMEL_TYPE_STREAM_PROCESS, CamelStreamProcess))
#define CAMEL_STREAM_PROCESS_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_CAST \
	((cls), CAMEL_TYPE_STREAM_PROCESS, CamelStreamProcessClass))
#define CAMEL_IS_STREAM_PROCESS(obj) \
	(G_TYPE_CHECK_INSTANCE_TYPE \
	((obj), CAMEL_TYPE_STREAM_PROCESS))
#define CAMEL_IS_STREAM_PROCESS_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_TYPE \
	((cls), CAMEL_TYPE_STREAM_PROCESS))
#define CAMEL_STREAM_PROCESS_GET_CLASS(obj) \
	(G_TYPE_INSTANCE_GET_CLASS \
	((obj), CAMEL_TYPE_STREAM_PROCSS, CamelStreamProcessClass))

G_BEGIN_DECLS

typedef struct _CamelStreamProcess CamelStreamProcess;
typedef struct _CamelStreamProcessClass CamelStreamProcessClass;
typedef struct _CamelStreamProcessPrivate CamelStreamProcessPrivate;

struct _CamelStreamProcess {
	CamelStream parent;
	CamelStreamProcessPrivate *priv;
};

struct _CamelStreamProcessClass {
	CamelStreamClass parent_class;

	/* Padding for future expansion */
	gpointer reserved[20];
};

GType		camel_stream_process_get_type	(void);
CamelStream *	camel_stream_process_new	(void);
gint		camel_stream_process_connect	(CamelStreamProcess *stream,
						 const gchar *command,
						 const gchar **env,
						 GError **error);

G_END_DECLS

#endif /* CAMEL_STREAM_PROCESS_H */
