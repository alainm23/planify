/* -*- Mode: C; tab-width: 8; indent-tabs-mode: t; c-basic-offset: 8; coding: utf-8 -*- */
/* gtksourcefileloader.h
 * This file is part of GtkSourceView
 *
 * Copyright (C) 2005 - Paolo Maggi
 * Copyright (C) 2007 - Paolo Maggi, Steve Frécinaux
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

#ifndef GTK_SOURCE_FILE_LOADER_H
#define GTK_SOURCE_FILE_LOADER_H

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

#define GTK_SOURCE_TYPE_FILE_LOADER              (gtk_source_file_loader_get_type())
#define GTK_SOURCE_FILE_LOADER(obj)              (G_TYPE_CHECK_INSTANCE_CAST((obj), GTK_SOURCE_TYPE_FILE_LOADER, GtkSourceFileLoader))
#define GTK_SOURCE_FILE_LOADER_CLASS(klass)      (G_TYPE_CHECK_CLASS_CAST((klass), GTK_SOURCE_TYPE_FILE_LOADER, GtkSourceFileLoaderClass))
#define GTK_SOURCE_IS_FILE_LOADER(obj)           (G_TYPE_CHECK_INSTANCE_TYPE((obj), GTK_SOURCE_TYPE_FILE_LOADER))
#define GTK_SOURCE_IS_FILE_LOADER_CLASS(klass)   (G_TYPE_CHECK_CLASS_TYPE ((klass), GTK_SOURCE_TYPE_FILE_LOADER))
#define GTK_SOURCE_FILE_LOADER_GET_CLASS(obj)    (G_TYPE_INSTANCE_GET_CLASS((obj), GTK_SOURCE_TYPE_FILE_LOADER, GtkSourceFileLoaderClass))

typedef struct _GtkSourceFileLoaderClass   GtkSourceFileLoaderClass;
typedef struct _GtkSourceFileLoaderPrivate GtkSourceFileLoaderPrivate;

#define GTK_SOURCE_FILE_LOADER_ERROR gtk_source_file_loader_error_quark ()

/**
 * GtkSourceFileLoaderError:
 * @GTK_SOURCE_FILE_LOADER_ERROR_TOO_BIG: The file is too big.
 * @GTK_SOURCE_FILE_LOADER_ERROR_ENCODING_AUTO_DETECTION_FAILED: It is not
 * possible to detect the encoding automatically.
 * @GTK_SOURCE_FILE_LOADER_ERROR_CONVERSION_FALLBACK: There was an encoding
 * conversion error and it was needed to use a fallback character.
 *
 * An error code used with the %GTK_SOURCE_FILE_LOADER_ERROR domain.
 */
typedef enum _GtkSourceFileLoaderError
{
	GTK_SOURCE_FILE_LOADER_ERROR_TOO_BIG,
	GTK_SOURCE_FILE_LOADER_ERROR_ENCODING_AUTO_DETECTION_FAILED,
	GTK_SOURCE_FILE_LOADER_ERROR_CONVERSION_FALLBACK
} GtkSourceFileLoaderError;

struct _GtkSourceFileLoader
{
	GObject parent;

	GtkSourceFileLoaderPrivate *priv;
};

struct _GtkSourceFileLoaderClass
{
	GObjectClass parent_class;

	gpointer padding[10];
};

GTK_SOURCE_AVAILABLE_IN_3_14
GType		 	 gtk_source_file_loader_get_type	(void) G_GNUC_CONST;

GTK_SOURCE_AVAILABLE_IN_3_14
GQuark			 gtk_source_file_loader_error_quark	(void);

GTK_SOURCE_AVAILABLE_IN_3_14
GtkSourceFileLoader	*gtk_source_file_loader_new		(GtkSourceBuffer         *buffer,
								 GtkSourceFile           *file);

GTK_SOURCE_AVAILABLE_IN_3_14
GtkSourceFileLoader	*gtk_source_file_loader_new_from_stream	(GtkSourceBuffer         *buffer,
								 GtkSourceFile           *file,
								 GInputStream            *stream);

GTK_SOURCE_AVAILABLE_IN_3_14
void			 gtk_source_file_loader_set_candidate_encodings
								(GtkSourceFileLoader     *loader,
								 GSList                  *candidate_encodings);

GTK_SOURCE_AVAILABLE_IN_3_14
GtkSourceBuffer		*gtk_source_file_loader_get_buffer	(GtkSourceFileLoader     *loader);

GTK_SOURCE_AVAILABLE_IN_3_14
GtkSourceFile		*gtk_source_file_loader_get_file	(GtkSourceFileLoader     *loader);

GTK_SOURCE_AVAILABLE_IN_3_14
GFile			*gtk_source_file_loader_get_location	(GtkSourceFileLoader     *loader);

GTK_SOURCE_AVAILABLE_IN_3_14
GInputStream		*gtk_source_file_loader_get_input_stream
								(GtkSourceFileLoader     *loader);

GTK_SOURCE_AVAILABLE_IN_3_14
void			 gtk_source_file_loader_load_async	(GtkSourceFileLoader     *loader,
								 gint                     io_priority,
								 GCancellable            *cancellable,
								 GFileProgressCallback    progress_callback,
								 gpointer                 progress_callback_data,
								 GDestroyNotify           progress_callback_notify,
								 GAsyncReadyCallback      callback,
								 gpointer                 user_data);

GTK_SOURCE_AVAILABLE_IN_3_14
gboolean		 gtk_source_file_loader_load_finish	(GtkSourceFileLoader     *loader,
								 GAsyncResult            *result,
								 GError                 **error);

GTK_SOURCE_AVAILABLE_IN_3_14
const GtkSourceEncoding	*gtk_source_file_loader_get_encoding	(GtkSourceFileLoader     *loader);

GTK_SOURCE_AVAILABLE_IN_3_14
GtkSourceNewlineType	 gtk_source_file_loader_get_newline_type (GtkSourceFileLoader    *loader);

GTK_SOURCE_AVAILABLE_IN_3_14
GtkSourceCompressionType gtk_source_file_loader_get_compression_type
								(GtkSourceFileLoader     *loader);

G_END_DECLS

#endif  /* GTK_SOURCE_FILE_LOADER_H  */
