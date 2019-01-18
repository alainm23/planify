/* -*- Mode: C; tab-width: 8; indent-tabs-mode: t; c-basic-offset: 8; coding: utf-8 -*- */
/* gtksourcefile.h
 * This file is part of GtkSourceView
 *
 * Copyright (C) 2014, 2015 - Sébastien Wilmet <swilmet@gnome.org>
 *
 * GtkSourceView is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * GtkSourceView is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
 */

#ifndef GTK_SOURCE_FILE_H
#define GTK_SOURCE_FILE_H

#if !defined (GTK_SOURCE_H_INSIDE) && !defined (GTK_SOURCE_COMPILATION)
#  if defined (__GNUC__)
#    warning "Only <gtksourceview/gtksource.h> can be included directly."
#  elif defined (G_OS_WIN32)
#    pragma message("Only <gtksourceview/gtksource.h> can be included directly.")
#  endif
#endif

#include <gtk/gtk.h>
#include <gtksourceview/gtksourcetypes.h>

G_BEGIN_DECLS

#define GTK_SOURCE_TYPE_FILE             (gtk_source_file_get_type ())
#define GTK_SOURCE_FILE(obj)             (G_TYPE_CHECK_INSTANCE_CAST ((obj), GTK_SOURCE_TYPE_FILE, GtkSourceFile))
#define GTK_SOURCE_FILE_CLASS(klass)     (G_TYPE_CHECK_CLASS_CAST ((klass), GTK_SOURCE_TYPE_FILE, GtkSourceFileClass))
#define GTK_SOURCE_IS_FILE(obj)          (G_TYPE_CHECK_INSTANCE_TYPE ((obj), GTK_SOURCE_TYPE_FILE))
#define GTK_SOURCE_IS_FILE_CLASS(klass)  (G_TYPE_CHECK_CLASS_TYPE ((klass), GTK_SOURCE_TYPE_FILE))
#define GTK_SOURCE_FILE_GET_CLASS(obj)   (G_TYPE_INSTANCE_GET_CLASS ((obj), GTK_SOURCE_TYPE_FILE, GtkSourceFileClass))

typedef struct _GtkSourceFileClass    GtkSourceFileClass;
typedef struct _GtkSourceFilePrivate  GtkSourceFilePrivate;

/**
 * GtkSourceNewlineType:
 * @GTK_SOURCE_NEWLINE_TYPE_LF: line feed, used on UNIX.
 * @GTK_SOURCE_NEWLINE_TYPE_CR: carriage return, used on Mac.
 * @GTK_SOURCE_NEWLINE_TYPE_CR_LF: carriage return followed by a line feed, used
 *   on Windows.
 *
 * Since: 3.14
 */
typedef enum _GtkSourceNewlineType
{
	GTK_SOURCE_NEWLINE_TYPE_LF,
	GTK_SOURCE_NEWLINE_TYPE_CR,
	GTK_SOURCE_NEWLINE_TYPE_CR_LF
} GtkSourceNewlineType;

/**
 * GTK_SOURCE_NEWLINE_TYPE_DEFAULT:
 *
 * The default newline type on the current OS.
 *
 * Since: 3.14
 */
#ifdef G_OS_WIN32
#define GTK_SOURCE_NEWLINE_TYPE_DEFAULT GTK_SOURCE_NEWLINE_TYPE_CR_LF
#else
#define GTK_SOURCE_NEWLINE_TYPE_DEFAULT GTK_SOURCE_NEWLINE_TYPE_LF
#endif

/**
 * GtkSourceCompressionType:
 * @GTK_SOURCE_COMPRESSION_TYPE_NONE: plain text.
 * @GTK_SOURCE_COMPRESSION_TYPE_GZIP: gzip compression.
 *
 * Since: 3.14
 */
typedef enum _GtkSourceCompressionType
{
	GTK_SOURCE_COMPRESSION_TYPE_NONE,
	GTK_SOURCE_COMPRESSION_TYPE_GZIP
} GtkSourceCompressionType;

/**
 * GtkSourceMountOperationFactory:
 * @file: a #GtkSourceFile.
 * @userdata: user data
 *
 * Type definition for a function that will be called to create a
 * #GMountOperation. This is useful for creating a #GtkMountOperation.
 *
 * Since: 3.14
 */
typedef GMountOperation *(*GtkSourceMountOperationFactory) (GtkSourceFile *file,
							    gpointer       userdata);

struct _GtkSourceFile
{
	GObject parent;

	GtkSourceFilePrivate *priv;
};

struct _GtkSourceFileClass
{
	GObjectClass parent_class;

	gpointer padding[10];
};

GTK_SOURCE_AVAILABLE_IN_3_14
GType		 gtk_source_file_get_type			(void) G_GNUC_CONST;

GTK_SOURCE_AVAILABLE_IN_3_14
GtkSourceFile	*gtk_source_file_new				(void);

GTK_SOURCE_AVAILABLE_IN_3_14
GFile		*gtk_source_file_get_location			(GtkSourceFile *file);

GTK_SOURCE_AVAILABLE_IN_3_14
void		 gtk_source_file_set_location			(GtkSourceFile *file,
								 GFile         *location);

GTK_SOURCE_AVAILABLE_IN_3_14
const GtkSourceEncoding *
		 gtk_source_file_get_encoding			(GtkSourceFile *file);

GTK_SOURCE_AVAILABLE_IN_3_14
GtkSourceNewlineType
		 gtk_source_file_get_newline_type		(GtkSourceFile *file);

GTK_SOURCE_AVAILABLE_IN_3_14
GtkSourceCompressionType
		 gtk_source_file_get_compression_type		(GtkSourceFile *file);

GTK_SOURCE_AVAILABLE_IN_3_14
void		 gtk_source_file_set_mount_operation_factory	(GtkSourceFile                  *file,
								 GtkSourceMountOperationFactory  callback,
								 gpointer                        user_data,
								 GDestroyNotify                  notify);

GTK_SOURCE_AVAILABLE_IN_3_18
void		 gtk_source_file_check_file_on_disk		(GtkSourceFile *file);

GTK_SOURCE_AVAILABLE_IN_3_18
gboolean	 gtk_source_file_is_local			(GtkSourceFile *file);

GTK_SOURCE_AVAILABLE_IN_3_18
gboolean	 gtk_source_file_is_externally_modified		(GtkSourceFile *file);

GTK_SOURCE_AVAILABLE_IN_3_18
gboolean	 gtk_source_file_is_deleted			(GtkSourceFile *file);

GTK_SOURCE_AVAILABLE_IN_3_18
gboolean	 gtk_source_file_is_readonly			(GtkSourceFile *file);

G_GNUC_INTERNAL
void		 _gtk_source_file_set_encoding			(GtkSourceFile           *file,
								 const GtkSourceEncoding *encoding);

G_GNUC_INTERNAL
void		 _gtk_source_file_set_newline_type		(GtkSourceFile        *file,
								 GtkSourceNewlineType  newline_type);

G_GNUC_INTERNAL
void		 _gtk_source_file_set_compression_type		(GtkSourceFile            *file,
								 GtkSourceCompressionType  compression_type);

G_GNUC_INTERNAL
GMountOperation	*_gtk_source_file_create_mount_operation	(GtkSourceFile *file);

G_GNUC_INTERNAL
gboolean	 _gtk_source_file_get_modification_time		(GtkSourceFile *file,
								 GTimeVal      *modification_time);

G_GNUC_INTERNAL
void		 _gtk_source_file_set_modification_time		(GtkSourceFile *file,
								 GTimeVal       modification_time);

G_GNUC_INTERNAL
void		 _gtk_source_file_set_externally_modified	(GtkSourceFile *file,
								 gboolean       externally_modified);

G_GNUC_INTERNAL
void		 _gtk_source_file_set_deleted			(GtkSourceFile *file,
								 gboolean       deleted);

G_GNUC_INTERNAL
void		 _gtk_source_file_set_readonly			(GtkSourceFile *file,
								 gboolean       readonly);

G_END_DECLS

#endif /* GTK_SOURCE_FILE_H */
