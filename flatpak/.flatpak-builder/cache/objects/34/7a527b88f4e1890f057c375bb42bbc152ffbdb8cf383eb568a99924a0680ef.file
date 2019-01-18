/* -*- Mode: C; tab-width: 8; indent-tabs-mode: t; c-basic-offset: 8; coding: utf-8 -*- */
/* gtksourcefilesaver.h
 * This file is part of GtkSourceView
 *
 * Copyright (C) 2005, 2007 - Paolo Maggi
 * Copyrhing (C) 2007 - Steve Frécinaux
 * Copyright (C) 2008 - Jesse van den Kieboom
 * Copyright (C) 2014 - Sébastien Wilmet
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

#ifndef GTK_SOURCE_FILE_SAVER_H
#define GTK_SOURCE_FILE_SAVER_H

#if !defined (GTK_SOURCE_H_INSIDE) && !defined (GTK_SOURCE_COMPILATION)
#  if defined (__GNUC__)
#    warning "Only <gtksourceview/gtksource.h> can be included directly."
#  elif defined (G_OS_WIN32)
#    pragma message("Only <gtksourceview/gtksource.h> can be included directly.")
#  endif
#endif

#include <gtk/gtk.h>
#include <gtksourceview/gtksourcetypes.h>
#include <gtksourceview/gtksourcefile.h>

G_BEGIN_DECLS

#define GTK_SOURCE_TYPE_FILE_SAVER              (gtk_source_file_saver_get_type())
#define GTK_SOURCE_FILE_SAVER(obj)              (G_TYPE_CHECK_INSTANCE_CAST((obj), GTK_SOURCE_TYPE_FILE_SAVER, GtkSourceFileSaver))
#define GTK_SOURCE_FILE_SAVER_CLASS(klass)      (G_TYPE_CHECK_CLASS_CAST((klass), GTK_SOURCE_TYPE_FILE_SAVER, GtkSourceFileSaverClass))
#define GTK_SOURCE_IS_FILE_SAVER(obj)           (G_TYPE_CHECK_INSTANCE_TYPE((obj), GTK_SOURCE_TYPE_FILE_SAVER))
#define GTK_SOURCE_IS_FILE_SAVER_CLASS(klass)   (G_TYPE_CHECK_CLASS_TYPE ((klass), GTK_SOURCE_TYPE_FILE_SAVER))
#define GTK_SOURCE_FILE_SAVER_GET_CLASS(obj)    (G_TYPE_INSTANCE_GET_CLASS((obj), GTK_SOURCE_TYPE_FILE_SAVER, GtkSourceFileSaverClass))

typedef struct _GtkSourceFileSaverClass   GtkSourceFileSaverClass;
typedef struct _GtkSourceFileSaverPrivate GtkSourceFileSaverPrivate;

#define GTK_SOURCE_FILE_SAVER_ERROR gtk_source_file_saver_error_quark ()

/**
 * GtkSourceFileSaverError:
 * @GTK_SOURCE_FILE_SAVER_ERROR_INVALID_CHARS: The buffer contains invalid
 *   characters.
 * @GTK_SOURCE_FILE_SAVER_ERROR_EXTERNALLY_MODIFIED: The file is externally
 *   modified.
 *
 * An error code used with the %GTK_SOURCE_FILE_SAVER_ERROR domain.
 * Since: 3.14
 */
typedef enum _GtkSourceFileSaverError
{
	GTK_SOURCE_FILE_SAVER_ERROR_INVALID_CHARS,
	GTK_SOURCE_FILE_SAVER_ERROR_EXTERNALLY_MODIFIED
} GtkSourceFileSaverError;

/**
 * GtkSourceFileSaverFlags:
 * @GTK_SOURCE_FILE_SAVER_FLAGS_NONE: No flags.
 * @GTK_SOURCE_FILE_SAVER_FLAGS_IGNORE_INVALID_CHARS: Ignore invalid characters.
 * @GTK_SOURCE_FILE_SAVER_FLAGS_IGNORE_MODIFICATION_TIME: Save file despite external modifications.
 * @GTK_SOURCE_FILE_SAVER_FLAGS_CREATE_BACKUP: Create a backup before saving the file.
 *
 * Flags to define the behavior of a #GtkSourceFileSaver.
 * Since: 3.14
 */
typedef enum _GtkSourceFileSaverFlags
{
	GTK_SOURCE_FILE_SAVER_FLAGS_NONE			= 0,
	GTK_SOURCE_FILE_SAVER_FLAGS_IGNORE_INVALID_CHARS	= 1 << 0,
	GTK_SOURCE_FILE_SAVER_FLAGS_IGNORE_MODIFICATION_TIME	= 1 << 1,
	GTK_SOURCE_FILE_SAVER_FLAGS_CREATE_BACKUP		= 1 << 2
} GtkSourceFileSaverFlags;

struct _GtkSourceFileSaver
{
	GObject object;

	GtkSourceFileSaverPrivate *priv;
};

struct _GtkSourceFileSaverClass
{
	GObjectClass parent_class;

	gpointer padding[10];
};

GTK_SOURCE_AVAILABLE_IN_3_14
GType			 gtk_source_file_saver_get_type		(void) G_GNUC_CONST;

GTK_SOURCE_AVAILABLE_IN_3_14
GQuark			 gtk_source_file_saver_error_quark	(void);

GTK_SOURCE_AVAILABLE_IN_3_14
GtkSourceFileSaver	*gtk_source_file_saver_new		(GtkSourceBuffer          *buffer,
								 GtkSourceFile            *file);

GTK_SOURCE_AVAILABLE_IN_3_14
GtkSourceFileSaver	*gtk_source_file_saver_new_with_target	(GtkSourceBuffer          *buffer,
								 GtkSourceFile            *file,
								 GFile                    *target_location);

GTK_SOURCE_AVAILABLE_IN_3_14
GtkSourceBuffer		*gtk_source_file_saver_get_buffer	(GtkSourceFileSaver       *saver);

GTK_SOURCE_AVAILABLE_IN_3_14
GtkSourceFile		*gtk_source_file_saver_get_file		(GtkSourceFileSaver       *saver);

GTK_SOURCE_AVAILABLE_IN_3_14
GFile			*gtk_source_file_saver_get_location	(GtkSourceFileSaver       *saver);

GTK_SOURCE_AVAILABLE_IN_3_14
void			 gtk_source_file_saver_set_encoding	(GtkSourceFileSaver       *saver,
								 const GtkSourceEncoding  *encoding);

GTK_SOURCE_AVAILABLE_IN_3_14
const GtkSourceEncoding *gtk_source_file_saver_get_encoding	(GtkSourceFileSaver       *saver);

GTK_SOURCE_AVAILABLE_IN_3_14
void			 gtk_source_file_saver_set_newline_type	(GtkSourceFileSaver       *saver,
								 GtkSourceNewlineType      newline_type);

GTK_SOURCE_AVAILABLE_IN_3_14
GtkSourceNewlineType	 gtk_source_file_saver_get_newline_type	(GtkSourceFileSaver       *saver);

GTK_SOURCE_AVAILABLE_IN_3_14
void			 gtk_source_file_saver_set_compression_type
								(GtkSourceFileSaver       *saver,
								 GtkSourceCompressionType  compression_type);

GTK_SOURCE_AVAILABLE_IN_3_14
GtkSourceCompressionType gtk_source_file_saver_get_compression_type
								(GtkSourceFileSaver       *saver);

GTK_SOURCE_AVAILABLE_IN_3_14
void			 gtk_source_file_saver_set_flags	(GtkSourceFileSaver       *saver,
								 GtkSourceFileSaverFlags   flags);

GTK_SOURCE_AVAILABLE_IN_3_14
GtkSourceFileSaverFlags	 gtk_source_file_saver_get_flags	(GtkSourceFileSaver       *saver);

GTK_SOURCE_AVAILABLE_IN_3_14
void			 gtk_source_file_saver_save_async	(GtkSourceFileSaver       *saver,
								 gint                      io_priority,
								 GCancellable             *cancellable,
								 GFileProgressCallback     progress_callback,
								 gpointer                  progress_callback_data,
								 GDestroyNotify            progress_callback_notify,
								 GAsyncReadyCallback       callback,
								 gpointer                  user_data);

GTK_SOURCE_AVAILABLE_IN_3_14
gboolean		 gtk_source_file_saver_save_finish	(GtkSourceFileSaver       *saver,
								 GAsyncResult             *result,
								 GError                  **error);

G_END_DECLS

#endif  /* GTK_SOURCE_FILE_SAVER_H  */
