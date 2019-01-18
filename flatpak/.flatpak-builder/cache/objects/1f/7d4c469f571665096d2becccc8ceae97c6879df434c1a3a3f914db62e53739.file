/* -*- Mode: C; tab-width: 8; indent-tabs-mode: t; c-basic-offset: 8 -*- */
/* camel-stream-fs.h :stream based on unix filesystem
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
 * Authors: Bertrand Guiheneuf <bertrand@helixcode.com>
 */

#if !defined (__CAMEL_H_INSIDE__) && !defined (CAMEL_COMPILATION)
#error "Only <camel/camel.h> can be included directly."
#endif

#ifndef CAMEL_STREAM_FS_H
#define CAMEL_STREAM_FS_H

/* for open flags */
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>

#include <camel/camel-stream.h>

/* Standard GObject macros */
#define CAMEL_TYPE_STREAM_FS \
	(camel_stream_fs_get_type ())
#define CAMEL_STREAM_FS(obj) \
	(G_TYPE_CHECK_INSTANCE_CAST \
	((obj), CAMEL_TYPE_STREAM_FS, CamelStreamFs))
#define CAMEL_STREAM_FS_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_CAST \
	((cls), CAMEL_TYPE_STREAM_FS, CamelStreamFsClass))
#define CAMEL_IS_STREAM_FS(obj) \
	(G_TYPE_CHECK_INSTANCE_TYPE \
	((obj), CAMEL_TYPE_STREAM_FS))
#define CAMEL_IS_STREAM_FS_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_TYPE \
	((cls), CAMEL_TYPE_STREAM_FS))
#define CAMEL_STREAM_FS_GET_CLASS(obj) \
	(G_TYPE_INSTANCE_GET_CLASS \
	((obj), CAMEL_TYPE_STREAM_FS, CamelStreamFsClass))

G_BEGIN_DECLS

typedef struct _CamelStreamFs CamelStreamFs;
typedef struct _CamelStreamFsClass CamelStreamFsClass;
typedef struct _CamelStreamFsPrivate CamelStreamFsPrivate;

struct _CamelStreamFs {
	CamelStream parent;
	CamelStreamFsPrivate *priv;
};

struct _CamelStreamFsClass {
	CamelStreamClass parent_class;

	/* Padding for future expansion */
	gpointer reserved[20];
};

GType		camel_stream_fs_get_type	(void);
CamelStream *	camel_stream_fs_new_with_name	(const gchar *name,
						 gint flags,
						 mode_t mode,
						 GError **error);
CamelStream *	camel_stream_fs_new_with_fd	(gint fd);
gint		camel_stream_fs_get_fd		(CamelStreamFs *stream);

G_END_DECLS

#endif /* CAMEL_STREAM_FS_H */
